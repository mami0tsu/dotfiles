"""GitHub file writes require an explicit branch and a verified blob SHA."""
from urllib.parse import quote
from mcp import call, context, done, need, reference, same, with_key
from github import preflight, resume_repository, current, get_call, repository

SKILL = "adapter-github-file"
KINDS = {"file"}


def read(payload, binding, operation, repo, ref, **extra):
    return call(payload, "github_fetch_file", {"repository_full_name": repo, "path": binding["target"]["path"], "ref": ref},
                context(binding, operation, repo=repo, ref=ref, **extra))


def file(raw, binding, ctx):
    url = raw.get("html_url") or raw.get("display_url") or raw.get("url")
    need(url and url.startswith("https://github.com/" + ctx["repo"] + "/blob/"), "file repository changed")
    need(url.endswith("/" + binding["target"]["path"]), "returned file path changed")
    need(raw.get("encoding") in (None, "utf-8"), "UTF-8 content is required")
    canonical = ctx.get("canonical_url") or url
    need(canonical.startswith("https://github.com/" + ctx["repo"] + "/blob/") and canonical.endswith("/" + binding["target"]["path"]), "canonical file identity changed")
    return reference(raw, canonical, canonical, raw.get("sha"), raw.get("content"), path=binding["target"]["path"],
                     ref=ctx["ref"], read_url=url, write_ref=ctx.get("write_ref"))


def prepare(payload, binding, operation):
    pending = preflight(payload, binding, operation)
    if pending:
        return pending
    data = payload.get("input", {})
    path = binding["target"]["path"]
    need(not path.startswith("/") and all(x not in ("", ".", "..") for x in path.split("/")), "file path must be relative without traversal")
    repo = repository(binding, data)
    ref = need(data.get("ref"), "explicit read ref or writable branch is required")
    if operation == "get":
        return read(payload, binding, operation, repo, ref, expected=data.get("expected"), canonical_url=data.get("url") or data.get("expected", {}).get("url"), write_ref=data.get("write_ref") or data.get("branch"))
    need(operation in ("create", "update", "save"), "unsupported file operation")
    need(data.get("branch") == ref, "explicit writable branch must equal ref")
    need(data.get("key"), "stable key is required")
    need(isinstance(data.get("content"), str), "UTF-8 replacement content is required")
    content = with_key(data["content"], data["key"])
    args = {"repository_full_name": repo, "path": binding["target"]["path"], "branch": ref,
            "content": content, "message": need(data.get("message"), "commit message is required") + "\n\nfactory-key: " + data["key"]}
    if operation == "create" or (operation == "save" and not data.get("expected")):
        path = binding["target"]["path"]
        parent = path.rsplit("/", 1)[0] if "/" in path else ""
        return get_call(payload, binding, operation, repo, "contents/" + quote(parent, safe="/") + "?ref=" + quote(ref, safe=""),
                        stage="absence", arguments=args, ref=ref, key=data["key"], canonical_url="https://github.com/" + repo + "/blob/" + ref + "/" + path)

    item = current(data, binding)
    need(item.get("path") == binding["target"]["path"] and (item.get("write_ref") or item.get("ref")) == ref, "file target changed")
    if item["body"] == content:
        return done(binding, [item], reused=True)
    args["sha"] = item["revision"]
    return call(payload, "github_update_file", args, context(binding, operation, repo=repo, ref=ref,
                stage="write", desired={"body": content}, key=data["key"], canonical_url=item["url"]))


def normalize(payload, binding, operation, ctx, raw):
    if ctx.get("stage") == "resolve-repository":
        from mcp import resource_module
        return resume_repository(resource_module(SKILL), payload, binding, operation, ctx, raw)
    if ctx.get("stage") == "absence":
        need(isinstance(raw, list), "parent directory is not a complete file listing")
        need(not any(x.get("path") == binding["target"]["path"] for x in raw), "file already exists; fetch and compare its blob SHA")
        need(len(raw) < 1000, "directory listing may be truncated")
        return call(payload, "github_create_file", ctx["arguments"], context(binding, operation, repo=ctx["repo"], ref=ctx["ref"],
                    stage="write", desired={"body": ctx["arguments"]["content"]}, key=ctx["key"], canonical_url=ctx["canonical_url"]))
    if ctx.get("stage") == "write":
        need(raw.get("commit_sha") or raw.get("sha"), "write commit is unknown; reconcile before retrying")
        commit = raw.get("commit_sha") or raw.get("sha")
        return read(payload, binding, operation, ctx["repo"], commit, stage="verify", desired=ctx["desired"], key=ctx["key"],
                    commit=commit, write_ref=ctx["ref"], expected_blob=raw.get("content_sha"), canonical_url=ctx.get("canonical_url"))
    item = file(raw, binding, ctx)
    if ctx.get("expected"):
        from mcp import expected
        expected(item, ctx["expected"])
    if ctx.get("desired"):
        same(item, ctx["desired"])
        need(item["key"] == ctx["key"], "stored file key differs from write intent")
        if ctx.get("expected_blob"):
            need(item["revision"] == ctx["expected_blob"], "stored blob differs from write result")
        item.update(commit=ctx["commit"], read_ref=ctx["commit"], write_ref=ctx["write_ref"])
    return done(binding, [item])
