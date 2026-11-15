"""Build GitHub resource calls with the connected MCP signatures."""
import re
from urllib.parse import quote, urlparse
from mcp import same_binding, call, context, done, expected, need, reference, same, unwrap


def repository(binding, data=None):
    value = binding["target"].get("container")
    if isinstance(value, str) and value.isdigit():
        raw = unwrap((data or {}).get("repository_response"))
        need(str(raw.get("id")) == value, "resolved repository ID changed")
        name = need(raw.get("repository_full_name"), "resolved repository name is missing")
        value = "https://github.com/" + name
    parsed = urlparse(value or "")
    need(parsed.scheme == "https" and parsed.netloc == "github.com" and not parsed.query and not parsed.fragment,
         "a canonical github.com repository URL is required")
    parts = parsed.path.strip("/").split("/")
    need(len(parts) == 2 and all(re.fullmatch(r"[A-Za-z0-9_.-]+", x) for x in parts), "repository URL is invalid")
    return "/".join(parts)


def subject(binding, data):
    ref = data.get("subject") or {k: data[k] for k in ("id", "url", "revision", "role", "team_id") if k in data}
    if binding["target"]["kind"] in ("collection", "change"):
        ref = {"role": binding["role"], **ref}
    if binding["target"]["kind"] in ("collection", "change"):
        repo = repository(binding, data)
        parsed = urlparse(ref.get("url", ""))
        parts = parsed.path.strip("/").split("/")
        need(parsed.netloc == "github.com" and "/".join(parts[:2]) == repo and len(parts) == 4, "subject repository changed")
        required = "issues" if binding["target"]["kind"] == "collection" else "pull"
        need(parts[2] == required and parts[3].isdigit(), "subject resource kind changed")
        need(ref.get("id") and ref.get("revision"), "subject reference is incomplete")
        return repo, int(parts[3]), parts[2], ref
    value = binding["target"]["subject"]
    if "url" in value:
        need(ref.get("url") == value["url"], "fixed comment subject changed")
    else:
        need(ref.get("role") == value["role"], "comment subject role changed")
    need(ref.get("id") and ref.get("revision"), "resolved subject ID and revision are required")
    parsed = urlparse(ref.get("url", ""))
    parts = parsed.path.strip("/").split("/")
    need(parsed.scheme == "https" and parsed.netloc == "github.com" and len(parts) == 4,
         "canonical comment subject URL is required")
    need(parts[2] in ("issues", "pull") and parts[3].isdigit() and not parsed.query and not parsed.fragment,
         "unsupported GitHub subject URL")
    return "/".join(parts[:2]), int(parts[3]), parts[2], ref


def number(data, repo=None, kind=None):
    value = data.get("number")
    ref = data.get("ref") if isinstance(data.get("ref"), dict) else {}
    url = data.get("url") or ref.get("url") or data.get("expected", {}).get("url")
    if url:
        parsed = urlparse(url)
        parts = parsed.path.strip("/").split("/")
        need(parsed.scheme == "https" and parsed.netloc == "github.com" and len(parts) == 4 and parts[3].isdigit(), "canonical GitHub resource URL is required")
        need(not repo or "/".join(parts[:2]) == repo, "resource repository changed")
        need(not kind or parts[2] == kind, "resource kind changed")
        derived = int(parts[3])
        need(value is None or value == derived, "GitHub number and URL disagree")
        value = derived
    need(type(value) is int and value > 0, "positive GitHub number or canonical resource URL is required")
    return value


def get_call(payload, binding, operation, repo, path, **extra):
    return call(payload, "github_fetch", {"url": "https://api.github.com/repos/" + repo + "/" + path},
                context(binding, operation, repo=repo, path=path, **extra))


def issue(item, repo):
    url = item.get("html_url") or item.get("url")
    need(url and url.startswith("https://github.com/" + repo + "/issues/"), "issue belongs to another repository or is a PR")
    need(not item.get("pull_request"), "pull request is not an issue")
    return reference(item, item.get("id"), url, item.get("updated_at"), item.get("body"),
                     number=item.get("number"), title=item.get("title"), state=item.get("state"),
                     labels=[x["name"] if isinstance(x, dict) else x for x in item.get("labels", [])],
                     author=item.get("user"), created_at=item.get("created_at"))


def pr(item, repo):
    url = item.get("html_url") or item.get("url")
    need(url and url.startswith("https://github.com/" + repo + "/pull/"), "PR repository changed")
    head = item.get("head")
    base = item.get("base")
    return reference(item, item.get("id") or item.get("number"), url,
                     head.get("sha") if isinstance(head, dict) else item.get("head_sha"), item.get("body"),
                     number=item.get("number"), title=item.get("title"), draft=item.get("draft"),
                     head=head.get("ref") if isinstance(head, dict) else head,
                     base=base.get("ref") if isinstance(base, dict) else base,
                     state=item.get("state"), author=item.get("user"), repository=repo,
                     requested_reviewers=[x["login"] for x in item.get("requested_reviewers") or []])


def current(data, binding):
    value = data.get("current", {})
    need(same_binding(value.get("binding"), binding) and value.get("complete") is True and len(value.get("items", [])) == 1,
         "fresh resource from the same binding is required")
    item = value["items"][0]
    expected(item, data.get("expected", {}))
    return item


def finish_or_page(payload, binding, operation, ctx, raw, normalize, filter_item=lambda x: True):
    need(isinstance(raw, list), "GitHub collection is not an array")
    items = ctx.get("items", []) + [normalize(x, ctx["repo"]) for x in raw if filter_item(x)]
    need(len({x["id"] for x in items}) == len(items), "collection changed during pagination")
    if len(raw) == 100:
        page = ctx.get("page", 1) + 1
        need(page <= 10000, "pagination limit reached")
        path = ctx["collection"] + "&page=" + str(page)
        return call(payload, "github_fetch", {"url": "https://api.github.com/repos/" + ctx["repo"] + "/" + path},
                    {**ctx, "path": path, "page": page, "items": items})
    need(len(raw) < 100, "GitHub page exceeds requested page size")
    return done(binding, items)


def verify_or_done(payload, binding, operation, ctx, raw, normalize):
    if ctx.get("stage") == "write":
        return get_call(payload, binding, operation, ctx["repo"], ctx["verify_path"],
                        stage="verify", desired=ctx["desired"])
    item = normalize(raw, ctx["repo"])
    path_parts = ctx.get("path", "").split("/")
    if len(path_parts) == 2 and path_parts[1].isdigit() and path_parts[0] in ("issues", "pulls"):
        need(item.get("number") == int(path_parts[1]), "returned GitHub number changed")
    for field, value in ctx.get("identity", {}).items():
        need(str(item.get(field)) == str(value), "returned resource " + field + " changed")
    if ctx.get("desired"):
        same(item, ctx["desired"])
    if ctx.get("expected"):
        expected(item, ctx["expected"])
    return done(binding, [item])


def preflight(payload, binding, operation):
    value = binding["target"].get("container", "")
    if value.isdigit() and not payload.get("input", {}).get("repository_response"):
        return call(payload, "github_get_repo", {"repository_id": int(value)},
                    context(binding, operation, stage="resolve-repository", input=payload.get("input", {})))
    return None


def resume_repository(module, payload, binding, operation, ctx, raw):
    data = {**ctx["input"], "repository_response": {"structuredContent": raw}}
    return module.prepare({**payload, "input": data}, binding, operation)
