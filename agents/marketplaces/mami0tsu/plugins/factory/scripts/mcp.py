"""Build MCP calls and check responses without opening a network connection."""
import json
import re
from copy import deepcopy

from common import Stop, load_config, require_ref, resolve_binding, run, stop


def need(value, reason):
    if value is None or value == "" or value is False:
        stop(reason)
    return value


def unwrap(raw):
    need(isinstance(raw, dict), "MCP response envelope is missing")
    if raw.get("isError"):
        stop("MCP failed; a write result may be unknown")
    data = raw.get("structuredContent")
    if data is None:
        texts = [x.get("text", "") for x in raw.get("content", []) if x.get("type") == "text"]
        need(len(texts) == 1, "MCP JSON response is ambiguous")
        try:
            data = json.loads(texts[0])
        except (ValueError, TypeError):
            stop("MCP response is not JSON")
    if isinstance(data, dict):
        if data.get("error") or data.get("errors") or data.get("error_code"):
            stop("MCP returned an API error; reconcile before retrying")
        if isinstance(data.get("content"), str):
            try:
                parsed = json.loads(data["content"])
            except ValueError:
                parsed = None
            if parsed is not None:
                return parsed
    return data


def call(payload, canonical, arguments, context):
    actual = payload.get("tools", {}).get(canonical)
    need(isinstance(actual, str) and actual, "verified MCP tool mapping is missing: " + canonical)
    return {"status": "success", "complete": False,
            "call": {"tool": actual, "arguments": arguments}, "context": context}


def keys(body):
    markers = re.findall(r"(?m)^(?:<!-- )?factory-key: ([A-Za-z0-9._:/-]+)(?: -->)?$", body or "")
    metadata = re.findall(r"<!-- factory-metadata\n(.*?)\n-->", body or "", re.DOTALL)
    need(len(metadata) <= 1, "resource metadata is ambiguous")
    if metadata:
        try:
            stored = json.loads(metadata[0])
        except ValueError:
            stop("resource metadata is not valid JSON")
        need(isinstance(stored, dict), "resource metadata is not an object")
        key = stored.get("key")
        if key is not None:
            need(isinstance(key, str) and re.fullmatch(r"[A-Za-z0-9._:/-]+", key), "stored metadata key is invalid")
            need(not markers or markers == [key], "body key and stored metadata key differ")
            return markers or [key]
    return markers


def with_key(body, key):
    need(isinstance(key, str) and re.fullmatch(r"[A-Za-z0-9._:/-]+", key), "stable key is missing or invalid")
    found = keys(body)
    need(not found or found == [key], "body has a different or repeated key")
    return body if found else (body.rstrip() + "\n\n<!-- factory-key: " + key + " -->")


def reference(item, ident, url, revision, body="", **extra):
    result = {"id": str(need(ident, "resource ID is missing")),
              "url": need(url, "canonical URL is missing"),
              "revision": need(revision, "resource revision is missing"),
              "body": body or "", **extra}
    found = keys(body)
    need(len(found) <= 1, "resource has ambiguous keys")
    result["key"] = found[0] if found else None
    return result


def expected(current, ref):
    require_ref(ref)
    for field in ("id", "url", "revision"):
        need(str(current.get(field)) == str(ref.get(field)), "expected " + field + " changed")
    if ref.get("key") is not None:
        need(current.get("key") == ref["key"], "expected key changed")


def inventory(value, binding):
    need(isinstance(value, dict) and value.get("status") == "success" and value.get("complete") is True,
         "complete inventory is required before creating")
    need(same_binding(value.get("binding"), binding), "inventory binding changed")
    need(isinstance(value.get("items"), list), "inventory items are missing")
    return value["items"]


def reusable(items, desired):
    found = [x for x in items if x.get("key") == desired["key"]]
    need(len(found) <= 1, "stable key matches multiple resources")
    if not found:
        return None
    same(found[0], desired)
    return found[0]


def same(resource, desired):
    for name, value in desired.items():
        need(resource.get(name) == value, "resource differs from requested " + name)


def done(binding, items, **extra):
    return {"status": "success", "complete": True, "binding": binding, "items": items, **extra}


def serve(module, operation):
    def handle(payload):
        config = load_config(payload)
        binding = resolve_binding(config, payload.get("role"), payload.get("output"), payload.get("expected_binding"))
        need(binding["definition"].get("skill") == module.SKILL, "selected adapter skill changed")
        kind = binding["target"].get("kind")
        need(kind in module.KINDS, "unsupported resource kind")
        role = binding["role"]
        need(role in (("ideas", "tasks") if kind == "collection" else ("staging", "artifacts", "changes")), "unsupported resource role")
        need(role != "changes" or kind == "change", "changes requires a change target")
        need(operation != "decision" or role == "ideas", "human decision reads require ideas")
        need(not (kind == "collection" and operation == "update" and role != "tasks"), "collection updates require tasks")
        if payload.get("phase", "prepare") == "prepare":
            return module.prepare(payload, binding, operation)
        need(payload.get("phase") == "normalize", "unknown MCP phase")
        context = deepcopy(payload.get("context", {}))
        need(same_binding(context.get("binding"), binding) and context.get("operation") == operation, "MCP context changed")
        try:
            return module.normalize(payload, binding, operation, context, unwrap(payload.get("response")))
        except Stop as exc:
            confirmed = payload.get("input", {}).get("current", {})
            items = confirmed.get("items", []) if same_binding(confirmed.get("binding"), binding) else []
            return {"status": exc.status, "complete": False, "binding": binding,
                    "items": items, "reason": str(exc), "context": context}
    run(handle)


def context(binding, operation, **extra):
    return {"binding": binding, "operation": operation, **extra}


def resource_module(skill):
    import importlib.util
    from pathlib import Path
    path = Path(__file__).resolve().parents[1] / "skills" / skill / "scripts/resource.py"
    spec = importlib.util.spec_from_file_location(skill.replace("-", "_"), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module



def same_binding(left, right):
    fields = ("adapter", "definition", "target", "output")
    return isinstance(left, dict) and isinstance(right, dict) and all(left.get(k) == right.get(k) for k in fields)
