import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
from common import Stop, load_config, require_ref, resolve_binding, stable_key, worker_input


def answers():
    return {
        "adapters": {"records": {"source": "builtin", "skill": "adapter-example"}},
        "roles": {role: {"adapter": "records", "target": {"kind": "collection", "container": "https://example.test/" + role}}
                  for role in ("ideas", "tasks")},
        "outputs": {"result": {"adapter": "records", "target": {"kind": "file", "container": "https://example.test/repo", "path": "result.md"}}},
        "states": {"ideas": {"adopted": "Accepted", "withdrawn": "Closed"}, "tasks": {"ready": "Ready"}},
    }


class CoreTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.config = str(Path(self.temporary.name) / "factory.json")
        self.payload = {"config": self.config}
        created = self.call("init_config", answers=answers())
        self.assertEqual(created["status"], "success", created)

    def call(self, name, **values):
        result = subprocess.run([sys.executable, str(SCRIPTS / (name + ".py"))],
                                input=json.dumps({**self.payload, **values}), text=True,
                                capture_output=True, check=True)
        return json.loads(result.stdout)

    def claim(self, skill="plan", suffix="a", **more):
        return self.call("loop_claim", skill=skill,
                         target={"id": suffix, "url": "https://example.test/" + suffix, "revision": "r1"},
                         step="work", **more)

    def attached(self, **kwargs):
        claim = self.claim(**kwargs)
        self.assertEqual(claim["status"], "success", claim)
        identity = {k: claim[k] for k in ("claim", "token")}
        self.assertEqual(self.call("loop_attach", **identity, child="native-1")["status"], "success")
        return {**identity, "child": "native-1"}

    def test_cue_defaults_and_no_overwrite(self):
        before = Path(self.config).read_bytes()
        result = self.call("init_config", answers={"garbage": True})
        self.assertFalse(result["created"])
        self.assertEqual(result["value"]["loop"]["concurrency"], 1)
        self.assertEqual(before, Path(self.config).read_bytes())
        Path(self.config).write_text("{invalid")
        self.assertEqual(self.call("init_config", answers=answers())["status"], "error")
        self.assertEqual(Path(self.config).read_text(), "{invalid")

    def test_missing_required_is_wait_and_absent(self):
        Path(self.config).unlink()
        result = self.call("init_config", answers={})
        self.assertEqual(result["status"], "wait", result)
        self.assertFalse(Path(self.config).exists())

    def test_missing_config_and_cue(self):
        Path(self.config).unlink()
        self.assertEqual(self.call("loop_status")["status"], "wait")
        env = {**os.environ, "FACTORY_CUE": "/missing/cue"}
        result = subprocess.run([sys.executable, str(SCRIPTS / "init_config.py")],
                                input=json.dumps({**self.payload, "answers": answers()}),
                                env=env, text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout)["status"], "wait")

    def test_cue_rejects_removed_worker_and_state(self):
        for key in ("worker", "state"):
            value = answers()
            if key == "worker":
                value["loop"] = {"skills": {"release": {"concurrency": 1}}}
            else:
                value["states"]["tasks"]["release-ready"] = "Ready"
            Path(self.config).write_text(json.dumps(value))
            self.assertEqual(self.call("loop_status")["status"], "error")

    def test_unknown_candidate_rejected(self):
        self.assertEqual(self.claim(skill="release")["status"], "error")
        self.assertEqual(self.call("loop_discover", manual=[{"skill": "release"}])["status"], "error")

    def test_init_creation_race(self):
        Path(self.config).unlink()
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
            results = list(executor.map(lambda _: self.call("init_config", answers=answers()), range(6)))
        self.assertTrue(all(r["status"] == "success" for r in results), results)
        self.assertEqual(sum(r["created"] for r in results), 1)

    def test_atomic_global_limit(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(lambda n: self.claim(suffix=str(n)), range(8)))
        self.assertEqual(sum(r["status"] == "success" for r in results), 1, results)
        self.assertEqual(len(self.call("loop_status")["entries"]), 1)

    def test_canonical_alias_shares_processing_limit(self):
        self.assertEqual(self.claim()["status"], "success")
        alias = Path(self.temporary.name) / "alias.json"
        alias.symlink_to(self.config)
        result = self.call("loop_claim", config=str(alias), skill="design", step="design",
                           target={"id": "b", "url": "https://example.test/b"})
        self.assertEqual(result["status"], "wait")
        self.assertFalse(alias.with_name(".alias.json.runtime.json").exists())

    def test_worker_limit_and_same_step_exclusion(self):
        config = answers()
        config["loop"] = {"concurrency": 3}
        Path(self.config).write_text(json.dumps(config))
        self.assertEqual(self.claim()["status"], "success")
        self.assertEqual(self.claim(suffix="b")["status"], "wait")
        self.assertEqual(self.claim(skill="design")["status"], "wait")
        self.assertEqual(self.claim(skill="design", suffix="b")["status"], "success")

    def test_target_excludes_different_step_and_preserves_input(self):
        value = answers()
        value["loop"] = {"concurrency": 4}
        Path(self.config).write_text(json.dumps(value))
        candidate = {"skill": "implement", "target": {"id": "x", "url": "https://example.test/x", "revision": "r1"},
                     "step": "implementation", "input": {"output": "result", "task": {"id": "x"}},
                     "refs": {"artifact": {"id": "a", "url": "https://example.test/artifact", "revision": "v1"}}}
        selected = self.call("loop_discover", manual=[candidate])["candidates"][0]
        claim = self.call("loop_claim", **selected)
        self.assertEqual(claim["input"], {**candidate["input"], "config": self.config,
                                         "journal": str(Path(self.config).with_name(".factory.json.writes.json"))})
        self.assertEqual(claim["refs"], candidate["refs"])
        entries = self.call("loop_status")["entries"]
        self.assertEqual(entries[claim["claim"]]["input"], claim["input"])
        review = {**candidate, "skill": "review", "step": "artifact-review"}
        self.assertEqual(self.call("loop_claim", **review)["status"], "wait")
        self.assertEqual(self.call("loop_discover", manual=[review])["candidates"], [])

    def test_minimal_manual_input_starts_write_intent(self):
        candidate = {"skill": "research", "target": {"id": "a", "url": "https://example.test/a"}, "step": "research"}
        discovered = self.call("loop_discover", manual=[candidate])["candidates"][0]
        claim = self.call("loop_claim", **discovered)
        child = {**claim["input"], "claim": claim["claim"], "token": claim["token"], "child": "native-writer"}
        self.assertEqual(child["config"], self.config)
        self.assertEqual(child["journal"], str(Path(self.config).with_name(".factory.json.writes.json")))
        self.assertEqual(worker_input(self.payload), claim["input"])
        self.assertEqual(self.call("loop_attach", **child)["status"], "success")
        self.assertEqual(self.call("loop_write", **child, key="new-record", operation="begin")["status"], "success")

    def test_child_cannot_switch_configuration_or_loop_journal(self):
        other = Path(self.temporary.name) / "other.json"
        other.write_bytes(Path(self.config).read_bytes())
        self.assertEqual(self.claim(input={"config": str(other)})["status"], "error")
        self.assertEqual(self.claim(input={"journal": str(other)})["status"], "error")
        alias = Path(self.temporary.name) / "alias.json"
        alias.symlink_to(self.config)
        result = self.claim(input={"config": str(alias)})
        self.assertEqual(result["status"], "success")
        self.assertEqual(result["input"]["config"], self.config)

    def test_standalone_worker_journal_default_and_explicit_path(self):
        normalized = worker_input(self.payload)
        self.assertTrue(Path(normalized["journal"]).is_absolute())
        custom = str(Path(self.temporary.name) / "explicit-writes.json")
        self.assertEqual(worker_input({**self.payload, "journal": custom})["journal"], custom)
        with self.assertRaises(Stop):
            worker_input({**self.payload, "journal": "relative.json"})

    def test_unconfirmed_child_holds_slot(self):
        claim = self.attached()
        result = self.call("loop_finish", **claim, result={"status": "wait"}, humanWait=True)
        self.assertEqual(result["phase"], "unknown")
        self.assertEqual(self.claim(suffix="b")["status"], "wait")
        self.assertEqual(self.call("loop_reconcile", **claim)["status"], "wait")

    def test_human_wait_releases_slot_and_ownership(self):
        claim = self.attached()
        bad = {**claim, "token": "wrong"}
        self.assertEqual(self.call("loop_finish", **bad, result={"status": "success"})["status"], "error")
        result = self.call("loop_finish", **claim, result={"status": "wait"}, humanWait=True, childTerminated=True)
        self.assertEqual(result["phase"], "waiting")
        self.assertEqual(self.claim(suffix="b")["status"], "success")

    def test_write_intent_retained_and_reconciled(self):
        claim = self.attached()
        self.assertEqual(self.call("loop_write", **claim, key="write-1", operation="begin")["status"], "success")
        self.assertEqual(self.call("loop_write", **claim, key="write-1", operation="begin")["status"], "wait")
        result = self.call("loop_finish", **claim, result={"status": "success"}, childTerminated=True)
        self.assertEqual(result["phase"], "unknown")
        self.assertEqual(self.call("loop_reconcile", **claim, childTerminated=True)["status"], "wait")
        result = self.call("loop_reconcile", **claim, childTerminated=True, writeChecks={"write-1": "observed"})
        self.assertEqual(result["status"], "success")
        self.assertEqual(self.claim(suffix="b")["status"], "success")

    def test_unattached_reservation_needs_absent_launch(self):
        result = self.claim()
        identity = {k: result[k] for k in ("claim", "token")}
        self.assertEqual(self.call("loop_reconcile", **identity, child=None, childTerminated=True)["status"], "wait")
        self.assertEqual(self.call("loop_reconcile", **identity, child=None, childTerminated=True, launchAbsent=True)["status"], "success")

    def test_discovery_manual_resume_and_periodic(self):
        config = answers()
        config["repositories"] = [{"url": "https://example.test/repo"}]
        Path(self.config).write_text(json.dumps(config))
        target = {"id": "x", "url": "https://example.test/x", "revision": "r1"}
        result = self.call("loop_discover", manual=[{"skill": "plan", "target": target, "step": "plan"}],
                           results=[{"status": "success", "next": "design", "target": target},
                                    {"status": "success", "next": "human", "target": target}])
        self.assertEqual([c["skill"] for c in result["candidates"]], ["plan", "research"])
        research = result["candidates"][-1]
        self.assertEqual(research["input"]["case"], "periodic")
        self.assertEqual(research["input"]["config"], self.config)
        self.assertEqual(research["input"]["completedAt"], 0)
        self.assertEqual(research["input"]["cycle"], research["target"]["revision"])
        claim = self.call("loop_claim", **research)
        identity = {k: claim[k] for k in ("claim", "token")}
        self.call("loop_attach", **identity, child="native-research")
        self.call("loop_finish", **identity, child="native-research", result={"status": "success"}, childTerminated=True)
        self.assertEqual(self.call("loop_discover")["candidates"], [])

    def test_ordinary_research_does_not_update_periodic_clock(self):
        value = answers()
        value["repositories"] = [{"url": "https://example.test/repo"}]
        Path(self.config).write_text(json.dumps(value))
        claim = self.claim(skill="research", input={"case": "idea"})
        identity = {k: claim[k] for k in ("claim", "token")}
        self.call("loop_attach", **identity, child="native-idea")
        self.call("loop_finish", **identity, child="native-idea", result={"status": "success"}, childTerminated=True)
        candidates = self.call("loop_discover")["candidates"]
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0]["input"]["case"], "periodic")
        self.assertEqual(candidates[0]["input"]["completedAt"], 0)

    def test_binding_identity_and_reference(self):
        config = load_config(self.payload)
        binding = resolve_binding(config, "artifacts", "result")
        self.assertEqual(binding["definition"]["skill"], "adapter-example")
        with self.assertRaises(Stop):
            resolve_binding(config, "artifacts", ["result"])
        with self.assertRaises(Stop):
            resolve_binding(config, "unknown", "result")
        with self.assertRaises(Stop):
            resolve_binding(config, "artifacts", "result", {"target": {"kind": "change"}})
        with self.assertRaises(Stop):
            require_ref({"id": "x", "url": "https://example.test/x"})
        self.assertEqual(stable_key({"a": 1, "b": 2}), stable_key({"b": 2, "a": 1}))

    def test_resume_next_without_restarting_human_wait(self):
        claim = self.attached()
        target = {"id": "a", "url": "https://example.test/a", "revision": "r1"}
        next_input = {"config": self.config, "output": "result", "current": {"id": "artifact", "revision": "r2"}}
        next_refs = {"source": target}
        self.call("loop_finish", **claim, childTerminated=True,
                  result={"status": "success", "next": "design", "target": target, "step": "design",
                          "nextInput": next_input, "nextRefs": next_refs})
        candidates = self.call("loop_discover")["candidates"]
        self.assertEqual([c["skill"] for c in candidates], ["design"])
        self.assertEqual(candidates[0]["input"], next_input)
        self.assertEqual(candidates[0]["refs"], next_refs)
        reservation = self.call("loop_claim", **candidates[0])
        identity = {k: reservation[k] for k in ("claim", "token")}
        self.call("loop_attach", **identity, child="native-design")
        self.call("loop_finish", **identity, child="native-design", childTerminated=True,
                  humanWait=True, result={"status": "wait", "next": "human"})
        self.assertEqual(self.call("loop_discover")["candidates"], [])
        self.assertEqual(self.call("loop_discover", manual=candidates)["candidates"], candidates)

    def test_reserved_claim_cannot_finish_without_native_lookup(self):
        claim = self.claim()
        identity = {k: claim[k] for k in ("claim", "token")}
        result = self.call("loop_finish", **identity, child=None, childTerminated=True,
                           result={"status": "success"})
        self.assertEqual(result["status"], "wait")
        self.assertEqual(self.claim(suffix="b")["status"], "wait")


if __name__ == "__main__":
    unittest.main()
