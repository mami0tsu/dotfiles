"""Linear resource helpers use only the connected MCP tool signatures."""
import re
from urllib.parse import urlparse
from mcp import same_binding, call, context, done, expected, need, reference, same, unwrap

FIELDS = ["id", "uuid", "title", "description", "url", "updatedAt", "createdAt", "createdById", "teamId", "parentId", "status", "relations", "stateHistory"]
LIST_FIELDS = [x for x in FIELDS if x not in ("relations", "stateHistory")]


def team(binding, data):
    container = binding["target"]["container"]
    if re.fullmatch(r"[0-9a-fA-F-]{36}", container):
        return container
    parsed = urlparse(container)
    parts = parsed.path.strip("/").split("/")
    need(parsed.scheme == "https" and parsed.netloc == "linear.app" and len(parts) == 4 and parts[1] == "team" and parts[3] == "all", "canonical Linear team URL or UUID is required")
    workspace = unwrap(data.get("workspace_response"))
    workspace = workspace.get("workspace", workspace.get("organization", {}))
    workspace_url = workspace.get("url") or ("https://linear.app/" + workspace.get("urlKey", ""))
    need(workspace_url.rstrip("/") == "https://linear.app/" + parts[0], "team workspace is unverified")
    resolved = unwrap(data.get("team_response"))
    need(resolved.get("key") == parts[2], "team key changed")
    return need(resolved.get("id"), "resolved team ID is missing")


def issue(item, team_id):
    need(item.get("teamId") == team_id, "issue team changed")
    need(isinstance(item.get("description"), str), "issue body is omitted; fetch full issue before comparing keys")
    return reference(item, item.get("id"), item.get("url"), item.get("updatedAt"), item.get("description"),
                     title=item.get("title"), state=item.get("status"), team_id=team_id, uuid=item.get("uuid"),
                     parent_id=item.get("parentId"), relations=item.get("relations"), state_history=item.get("stateHistory"),
                     author=item.get("createdById"), created_at=item.get("createdAt"))


def current(data, binding):
    value = data.get("current", {})
    need(value.get("complete") is True and same_binding(value.get("binding"), binding) and len(value.get("items", [])) == 1,
         "fresh resource from the same binding is required")
    item = value["items"][0]
    expected(item, data.get("expected", {}))
    return item


def paged(payload, binding, operation, ctx, raw, field, normalize, canonical, arguments):
    need(isinstance(raw, dict) and isinstance(raw.get(field), list) and type(raw.get("hasNextPage")) is bool,
         "Linear pagination metadata is missing")
    items = ctx.get("items", []) + [normalize(x) for x in raw[field]]
    need(len({x["id"] for x in items}) == len(items), "collection changed during pagination")
    if raw["hasNextPage"]:
        cursor = need(raw.get("cursor"), "next cursor is missing")
        cursors = ctx.get("cursors", [])
        need(cursor not in cursors, "Linear cursor repeated")
        args = {**arguments, "cursor": cursor}
        return call(payload, canonical, args, {**ctx, "items": items, "cursors": cursors + [cursor]})
    return done(binding, items)


def subject(binding, data):
    ref = data.get("subject") or {k: data[k] for k in ("id", "url", "revision", "role", "team_id") if k in data}
    if binding["target"]["kind"] in ("collection", "change"):
        ref = {"role": binding["role"], **ref}
    need(ref.get("id") and ref.get("url") and ref.get("revision"), "resolved issue subject is required")
    need("/issue/" in ref["url"] and ref["url"].startswith("https://linear.app/"), "Linear issue subject URL is required")
    if binding["target"]["kind"] == "collection":
        need(ref.get("team_id", team(binding, data)) == team(binding, data), "comment subject team changed")
    else:
        value = binding["target"]["subject"]
        need(ref.get("url") == value.get("url") if "url" in value else ref.get("role") == value["role"], "comment subject changed")
    return ref
