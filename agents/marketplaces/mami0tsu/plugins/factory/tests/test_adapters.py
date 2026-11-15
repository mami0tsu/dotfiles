"""Exercise MCP signatures, observed read envelopes, and unsafe result boundaries."""
import copy
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / "scripts"), str(ROOT / "scripts/providers")]
from common import Stop
import mcp
from github import issue as github_issue, pr
from linear import issue as linear_issue

TEAM = "e144bce9-a34b-4fa5-b69c-68234b565d6a"
TOOLS = {name: "mcp__codex_apps__" + name for name in (
    "github_get_repo", "github_fetch", "github_create_issue", "github_update_issue", "github_create_pull_request", "github_update_pull_request",
    "github_request_pull_request_reviewers", "github_fetch_file", "github_create_file", "github_update_file", "github_add_comment_to_issue", "github_update_issue_comment",
    "linear_get_issue", "linear_list_issues", "linear_save_issue", "linear_list_comments", "linear_save_comment")}
FIXTURES = json.loads((Path(__file__).parent / "fixtures/mcp-read.json").read_text())


def binding(skill, kind, role="tasks"):
    target = {"kind": kind}
    if kind in ("collection", "file", "change"):
        target["container"] = TEAM if "linear" in skill else "https://github.com/acme/repo"
    if kind == "file":
        target["path"] = "docs/design.md"
    if kind == "change":
        target["base"] = "main"
    if kind == "comment":
        target["subject"] = {"role": "tasks"}
    return {"role": role, "output": None if role in ("ideas", "tasks") else "docs", "adapter": "chosen",
            "definition": {"source": "builtin", "skill": skill}, "target": target}


def gh_item(num=1, key="k", body=None):
    return {"id": num, "number": num, "html_url": "https://github.com/acme/repo/issues/" + str(num),
            "updated_at": "v1", "body": body if body is not None else "body\n\n<!-- factory-key: " + key + " -->", "title": "title"}


def li_item(num=1, key="k"):
    return {"id": "P-" + str(num), "url": "https://linear.app/acme/issue/P-" + str(num), "teamId": TEAM,
            "updatedAt": "v1", "description": "body\n\n<!-- factory-key: " + key + " -->", "title": "title", "status": "Backlog"}


class Adapters(unittest.TestCase):
    def module(self, skill):
        return mcp.resource_module(skill)

    def request(self, **data):
        return {"tools": TOOLS, "input": data}

    def assertWait(self, fn, *args):
        with self.assertRaises(Stop) as result:
            fn(*args)
        self.assertEqual(result.exception.status, "wait")

    def test_observed_envelopes_and_api_error(self):
        self.assertEqual(mcp.unwrap(FIXTURES["github_get"]), [])
        self.assertEqual(mcp.unwrap(FIXTURES["linear_comments"])["hasNextPage"], False)
        self.assertEqual(pr(mcp.unwrap(FIXTURES["github_pr"]), "mami0tsu/dotfiles")["revision"], "5e2d7a4a36912df3b3240b26d3143167cad20adf")
        self.assertEqual(linear_issue(mcp.unwrap(FIXTURES["linear_issue"]), TEAM)["id"], "P-106")
        self.assertWait(mcp.unwrap, FIXTURES["github_error"])
        self.assertWait(mcp.unwrap, {"content": [{"type": "text", "text": "Action completed."}]})
        self.assertWait(mcp.unwrap, {"structuredContent": {"errors": ["denied"]}})

    def test_github_pagination_filters_pr_and_requires_terminal_page(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        request = self.request()
        first = module.prepare(request, bind, "list")
        self.assertEqual(first["call"]["arguments"], {"url": "https://api.github.com/repos/acme/repo/issues?state=all&per_page=100&page=1"})
        page = [gh_item(i, str(i)) for i in range(1, 101)]
        page[0]["pull_request"] = {}
        next_page = module.normalize(request, bind, "list", first["context"], page)
        self.assertFalse(next_page["complete"])
        self.assertIn("page=2", next_page["call"]["arguments"]["url"])
        result = module.normalize(request, bind, "list", next_page["context"], [])
        self.assertTrue(result["complete"])
        self.assertEqual(len(result["items"]), 99)

    def test_github_missing_revision_and_cross_repo_are_wait(self):
        item = gh_item()
        item.pop("updated_at")
        self.assertWait(github_issue, item, "acme/repo")
        self.assertWait(github_issue, gh_item(), "other/repo")

    def test_exact_key_reuse_not_substring_and_no_incomplete_create(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        full = mcp.done(bind, [github_issue(gh_item(key="key-long"), "acme/repo")])
        request = self.request(key="key", title="title", body="body", inventory=full)
        call = module.prepare(request, bind, "create")
        self.assertEqual(call["call"]["tool"], TOOLS["github_create_issue"])
        self.assertEqual(call["call"]["arguments"]["body"], "body\n\n<!-- factory-key: key -->")
        request["input"]["key"] = "key-long"
        self.assertTrue(module.prepare(request, bind, "create")["reused"])
        full["items"].append(copy.deepcopy(full["items"][0]))
        self.assertWait(module.prepare, request, bind, "create")
        full["complete"] = False
        self.assertWait(module.prepare, request, bind, "create")

    def test_update_expected_version_and_unknown_write(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        item = github_issue(gh_item(), "acme/repo")
        request = self.request(key="k", title="title", body="new", current=mcp.done(bind, [item]), expected={**item, "revision": "old"})
        self.assertWait(module.prepare, request, bind, "update")
        request["input"]["expected"] = item
        result = module.prepare(request, bind, "update")
        self.assertWait(module.normalize, request, bind, "update", result["context"], {**gh_item(), "updated_at": "v2"})
        result = module.normalize(request, bind, "update", result["context"], gh_item())
        verify = module.normalize(request, bind, "update", result["context"], {"issue": {"issue_number": 1}})
        self.assertFalse(verify["complete"])
        self.assertWait(module.normalize, request, bind, "update", verify["context"], gh_item(body="different"))

    def test_pr_draft_and_task_repository_lease(self):
        module = self.module("adapter-github-pr")
        bind = binding(module.SKILL, "change", "changes")
        request = self.request(key="k", title="title", body="https://linear.app/acme/issue/P-1", task={"id": "P-1", "url": "https://linear.app/acme/issue/P-1"}, head="feature/P-1", revision="headsha", inventory=mcp.done(bind, []))
        result = module.prepare(request, bind, "create")
        self.assertIs(result["call"]["arguments"]["draft"], True)
        self.assertEqual(result["call"]["arguments"]["base"], "main")
        request["input"]["task"]["change"] = {"repository": "other/repo", "key": "k"}
        self.assertWait(module.prepare, request, bind, "create")
        self.assertWait(module.prepare, request, bind, "merge")

    def test_file_blob_sha_and_create_absence(self):
        module = self.module("adapter-github-file")
        bind = binding(module.SKILL, "file", "artifacts")
        data = {"content": "old", "sha": "blob1", "encoding": "utf-8", "display_url": "https://github.com/acme/repo/blob/topic/docs/design.md"}
        ctx = {"repo": "acme/repo", "ref": "topic"}
        item = module.file(data, bind, ctx)
        request = self.request(content="new", ref="topic", branch="topic", key="k", message="update", current=mcp.done(bind, [item]), expected=item)
        result = module.prepare(request, bind, "update")
        self.assertEqual(result["call"]["arguments"]["sha"], "blob1")
        self.assertEqual(result["call"]["arguments"]["branch"], "topic")
        result = module.prepare(request, bind, "create")
        self.assertIn("contents/docs?ref=topic", result["call"]["arguments"]["url"])
        self.assertWait(module.normalize, request, bind, "create", result["context"], [{"path": "docs/design.md"}])
        created = module.normalize(request, bind, "create", result["context"], [])
        self.assertEqual(created["call"]["tool"], TOOLS["github_create_file"])

    def test_github_issue_comment_is_not_coerced_to_pr(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        parent = {"id": "1", "url": "https://github.com/acme/repo/issues/1", "revision": "v1", "role": "tasks"}
        request = self.request(subject=parent, key="k", body="body")
        self.assertWait(module.prepare, request, bind, "comment")
        self.assertIn("issues/1/comments", module.prepare(request, bind, "comments")["call"]["arguments"]["url"])

    def test_linear_cursor_contract_and_missing_metadata(self):
        module = self.module("adapter-linear-issue")
        bind = binding(module.SKILL, "collection")
        request = self.request()
        first = module.prepare(request, bind, "list")
        self.assertIs(first["call"]["arguments"]["includeArchived"], True)
        self.assertIn("description", first["call"]["arguments"]["fields"])
        self.assertWait(module.normalize, request, bind, "list", first["context"], {"issues": []})
        second = module.normalize(request, bind, "list", first["context"], {"issues": [li_item()], "hasNextPage": True, "cursor": "c"})
        self.assertEqual(second["call"]["arguments"]["cursor"], "c")
        self.assertWait(module.normalize, request, bind, "list", second["context"], {"issues": [], "hasNextPage": True, "cursor": "c"})
        final = module.normalize(request, bind, "list", second["context"], {"issues": [], "hasNextPage": False})
        self.assertEqual(len(final["items"]), 1)

    def test_linear_create_signature_and_post_read(self):
        module = self.module("adapter-linear-issue")
        bind = binding(module.SKILL, "collection")
        request = self.request(key="k", title="title", body="body", inventory=mcp.done(bind, []), relations={"parentId": "P-9", "blocks": ["P-2"], "blockedBy": ["P-3"]})
        result = module.prepare(request, bind, "create")
        args = result["call"]["arguments"]
        self.assertEqual(args["team"], TEAM)
        self.assertEqual(args["blocks"], ["P-2"])
        self.assertEqual(args["blockedBy"], ["P-3"])
        result = module.normalize(request, bind, "create", result["context"], {"id": "P-1"})
        self.assertEqual(result["call"]["arguments"]["id"], "P-1")
        result = module.normalize(request, bind, "create", result["context"], li_item())
        self.assertTrue(result["complete"])

    def test_linear_comment_parent_and_thread_root(self):
        module = self.module("adapter-linear-comment")
        bind = binding(module.SKILL, "comment", "artifacts")
        parent = {"id": "P-1", "url": "https://linear.app/acme/issue/P-1", "revision": "v1", "role": "tasks"}
        request = self.request(subject=parent)
        first = module.prepare(request, bind, "list")
        items = [{"id": "a", "body": "root", "updatedAt": "v1", "parentId": None}, {"id": "b", "body": "reply", "updatedAt": "v1", "parentId": "a", "onBehalfOf": {"id": "human"}}]
        final = module.normalize(request, bind, "list", first["context"], {"comments": items, "hasNextPage": False})
        self.assertEqual(final["items"][1]["root_id"], "a")
        self.assertEqual(final["items"][1]["on_behalf_of"], {"id": "human"})
        items[1]["parentId"] = "missing"
        self.assertWait(module.normalize, request, bind, "list", first["context"], {"comments": items, "hasNextPage": False})
        request["input"].update(key="k", body="body", parent_id="a")
        self.assertWait(module.prepare, request, bind, "create")

    def test_linear_comment_write_rechecks_parent_and_lists_after_save(self):
        module = self.module("adapter-linear-comment")
        bind = binding(module.SKILL, "comment", "artifacts")
        parent = {"id": "P-1", "url": "https://linear.app/acme/issue/P-1", "revision": "v1", "role": "tasks"}
        inv = {**mcp.done(bind, []), "subject": parent}
        request = self.request(subject=parent, key="k", body="body", inventory=inv)
        first = module.prepare(request, bind, "save")
        self.assertEqual(first["call"]["tool"], TOOLS["linear_get_issue"])
        self.assertWait(module.normalize, request, bind, "save", first["context"], {"id": "P-1", "url": parent["url"], "updatedAt": "v2"})
        saved = module.normalize(request, bind, "save", first["context"], {"id": "P-1", "url": parent["url"], "updatedAt": "v1"})
        self.assertEqual(saved["call"]["arguments"], {"issueId": "P-1", "body": "body\n\n<!-- factory-key: k -->"})
        verify = module.normalize(request, bind, "save", saved["context"], {"id": "comment-1"})
        self.assertEqual(verify["call"]["tool"], TOOLS["linear_list_comments"])

    def test_cli_uses_cue_binding_and_checks_context(self):
        if not shutil.which(os.environ.get("FACTORY_CUE", "cue")):
            self.skipTest("CUE is not installed")
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "factory.json"
            for skill, kind in (("adapter-github-issue", "collection"), ("adapter-linear-issue", "collection"),
                               ("adapter-github-pr", "change"), ("adapter-github-file", "file"),
                               ("adapter-github-comment", "comment"), ("adapter-linear-comment", "comment")):
                role = "tasks" if kind == "collection" else "artifacts"
                bind = binding(skill, kind, role)
                config = {"adapters": {"chosen": bind["definition"]},
                          "roles": {r: {"adapter": "chosen", "target": {"kind": "collection", "container": TEAM if "linear" in skill else "https://github.com/acme/repo"}} for r in ("ideas", "tasks")},
                          "outputs": {"docs": {"adapter": "chosen", "target": bind["target"] if kind != "collection" else {"kind": "file", "container": "https://github.com/acme/repo", "path": "doc.md"}}},
                          "states": {"ideas": {"adopted": "Accepted", "withdrawn": "Closed"}, "tasks": {"ready": "Ready"}}}
                path.write_text(json.dumps(config))
                data = {"number": 1, "id": "P-1", "ref": "topic", "comment_id": "c",
                        "subject": {"id": "1", "url": "https://github.com/acme/repo/pull/1", "revision": "v1", "role": "tasks"}}
                if "linear" in skill:
                    data["subject"].update(id="P-1", url="https://linear.app/acme/issue/P-1")
                payload = {"config": str(path), "role": role, "output": "docs", "tools": TOOLS, "input": data}
                script = ROOT / "skills" / skill / "scripts/get.py"
                result = subprocess.run([sys.executable, str(script)], input=json.dumps(payload), text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                first = json.loads(result.stdout)
                self.assertEqual(first["status"], "success", (skill, first))
                self.assertIn("call", first)
                payload.update(phase="normalize", context={**first["context"], "binding": {}}, response=FIXTURES["github_get"])
                result = subprocess.run([sys.executable, str(script)], input=json.dumps(payload), text=True, capture_output=True, check=True)
                self.assertEqual(json.loads(result.stdout)["status"], "wait")

    def test_decision_returns_original_human_source_without_adoption(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection", "ideas")
        request = self.request(url="https://github.com/acme/repo/issues/1")
        first = module.prepare(request, bind, "decision")
        comments = module.normalize(request, bind, "decision", first["context"], gh_item())
        raw = [{"id": 5, "html_url": "https://github.com/acme/repo/issues/1#issuecomment-5", "updated_at": "v2", "body": "Adopt this plan", "user": {"id": 7, "login": "human", "type": "User"}}]
        result = module.normalize(request, bind, "decision", comments["context"], raw)
        self.assertTrue(result["complete"])
        self.assertEqual(result["evidence"][0]["body"], "Adopt this plan")
        self.assertEqual(result["evidence"][0]["actor"], "7")
        self.assertEqual(result["evidence"][0]["subject"]["revision"], "v1")
        self.assertNotIn("decision", result)

    def test_linear_relation_changes_are_set_differences(self):
        module = self.module("adapter-linear-issue")
        bind = binding(module.SKILL, "collection")
        raw = li_item()
        raw["relations"] = {"blocks": [{"id": "P-2"}, {"id": "P-3"}], "blockedBy": [{"id": "P-9"}]}
        item = linear_issue(raw, TEAM)
        request = self.request(key="k", body="body", title="title", current=mcp.done(bind, [item]), expected=item,
                               relations={"blocks": ["P-3", "P-4"], "blockedBy": ["P-8"]})
        before = module.prepare(request, bind, "update")
        result = module.normalize(request, bind, "update", before["context"], raw)
        self.assertEqual(result["call"]["arguments"]["blocks"], ["P-4"])
        self.assertEqual(result["call"]["arguments"]["removeBlocks"], ["P-2"])
        self.assertEqual(result["call"]["arguments"]["blockedBy"], ["P-8"])
        self.assertEqual(result["call"]["arguments"]["removeBlockedBy"], ["P-9"])

    def test_repository_id_is_resolved_with_the_existing_mcp(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        bind["target"]["container"] = "123"
        request = self.request(url="https://github.com/acme/repo/issues/1")
        first = module.prepare(request, bind, "get")
        self.assertEqual(first["call"]["arguments"], {"repository_id": 123})
        self.assertWait(module.normalize, request, bind, "get", first["context"], {"id": "124", "repository_full_name": "acme/repo"})
        second = module.normalize(request, bind, "get", first["context"], {"id": "123", "repository_full_name": "acme/repo"})
        self.assertEqual(second["call"]["arguments"]["url"], "https://api.github.com/repos/acme/repo/issues/1")

    def test_output_role_aliases_share_identity_but_not_changed_targets(self):
        module = self.module("adapter-github-file")
        bind = binding(module.SKILL, "file", "staging")
        raw = {"content": "old\n\n<!-- factory-key: k -->", "sha": "blob1", "display_url": "https://github.com/acme/repo/blob/topic/docs/design.md"}
        item = module.file(raw, bind, {"repo": "acme/repo", "ref": "topic"})
        current = mcp.done(bind, [item])
        artifacts = {**bind, "role": "artifacts"}
        request = self.request(content="old", ref="topic", branch="topic", key="k", message="save", current=current, expected=item)
        self.assertTrue(module.prepare(request, artifacts, "save")["reused"])
        bad = {**artifacts, "output": "other"}
        self.assertWait(module.prepare, request, bad, "save")
        bad = {**artifacts, "target": {**artifacts["target"], "path": "other.md"}}
        self.assertWait(module.prepare, request, bad, "save")

    def test_saved_file_key_and_commit_are_recovered_on_later_get(self):
        module = self.module("adapter-github-file")
        bind = binding(module.SKILL, "file", "artifacts")
        body = "content\n\n<!-- factory-metadata\n" + json.dumps({"key": "k", "output": "docs"}) + "\n-->"
        raw = {"content": body, "sha": "blob1", "display_url": "https://github.com/acme/repo/blob/topic/docs/design.md"}
        item = module.file(raw, bind, {"repo": "acme/repo", "ref": "topic"})
        self.assertEqual(item["key"], "k")
        request = self.request(content=body, ref="topic", branch="topic", key="k", message="save", current=mcp.done(bind, [item]), expected=item)
        self.assertTrue(module.prepare(request, bind, "save")["reused"])
        ctx = {"stage": "write", "repo": "acme/repo", "ref": "topic", "desired": {"body": body}, "key": "k"}
        verify = module.normalize(request, bind, "save", ctx, {"commit_sha": "commit1", "content_sha": "blob1"})
        self.assertEqual(verify["call"]["arguments"]["ref"], "commit1")
        saved = module.normalize(request, bind, "save", verify["context"], raw)["items"][0]
        self.assertEqual(saved["read_ref"], "commit1")
        self.assertEqual(saved["write_ref"], "topic")
        self.assertEqual(saved["key"], "k")

    def test_review_request_rechecks_head_and_keeps_draft_for_humans(self):
        from unittest.mock import patch
        module = self.module("adapter-github-pr")
        bind = binding(module.SKILL, "change", "changes")
        raw = {"id": 1, "number": 1, "html_url": "https://github.com/acme/repo/pull/1", "head": {"sha": "sha1", "ref": "topic"}, "base": {"ref": "main"}, "state": "open", "draft": True, "body": "body"}
        item = pr(raw, "acme/repo")
        request = self.request(url=item["url"], expected=item)
        with patch("common.load_config", return_value={"reviewers": {"default": ["reviewer"]}}):
            first = module.prepare(request, bind, "request-review")
        self.assertWait(module.normalize, request, bind, "request-review", first["context"], raw)
        raw["draft"] = False
        write = module.normalize(request, bind, "request-review", first["context"], raw)
        self.assertEqual(write["call"]["arguments"]["reviewers"], ["reviewer"])
        verify = module.normalize(request, bind, "request-review", write["context"], {})
        raw["requested_reviewers"] = [{"login": "reviewer"}]
        result = module.normalize(request, bind, "request-review", verify["context"], raw)
        self.assertEqual(result["review_requested"], ["reviewer"])

    def test_get_rejects_another_resource_even_in_the_same_repository(self):
        module = self.module("adapter-github-issue")
        bind = binding(module.SKILL, "collection")
        request = self.request(id="1", url="https://github.com/acme/repo/issues/1", revision="v0")
        first = module.prepare(request, bind, "get")
        self.assertWait(module.normalize, request, bind, "get", first["context"], gh_item(2))
        self.assertEqual(module.normalize(request, bind, "get", first["context"], gh_item())["items"][0]["revision"], "v1")

    def test_metadata_and_minimal_skill_contract(self):
        import yaml
        for path in (ROOT / "skills").glob("adapter-*/SKILL.md"):
            content = path.read_text()
            metadata = yaml.safe_load(content.split("---", 2)[1])
            self.assertEqual(metadata["name"], path.parent.name)
            self.assertLessEqual(len(content.splitlines()), 45)
            self.assertEqual([x for x in content.splitlines() if x.startswith("## ")], ["## 入力", "## 出力", "## 制約", "## 手順"])
            self.assertTrue((path.parent / "agents/openai.yaml").exists())
            self.assertTrue((path.parent / "assets/result.md").exists())
            self.assertNotIn("gh api", metadata["allowed-tools"])


if __name__ == "__main__":
    unittest.main()
