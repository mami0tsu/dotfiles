"""Top-level GitHub comments preserve the parent revision and stable key."""
from mcp import call, context, done, expected, inventory, need, reference, reusable, same, with_key
from github import current, finish_or_page, get_call, pr, subject

SKILL = "adapter-github-comment"
KINDS = {"comment"}


def comment(item, repo):
    url = item.get("html_url") or item.get("url")
    need(url and url.startswith("https://github.com/" + repo + "/"), "comment repository changed")
    return reference(item, item.get("id"), url, item.get("updated_at"), item.get("body"),
                     author=item.get("user"), created_at=item.get("created_at"),
                     parent_id=None, root_id=str(item.get("id")), kind="top-level")


def prepare(payload, binding, operation):
    data = payload.get("input", {})
    repo, num, kind, parent = subject(binding, data)
    collection = "issues/" + str(num) + "/comments?per_page=100"
    if operation in ("list", "get", "comments"):
        return get_call(payload, binding, operation, repo, collection + "&page=1", page=1, collection=collection,
                        selected=data.get("comment_id") or data.get("id"), expected=data.get("expected"), subject=parent)
    need(operation in ("create", "update", "save", "comment"), "unsupported comment operation")
    need(kind == "pull", "connected MCP supports comment writes on PR conversations only")
    need(not data.get("parent_id") and data.get("kind", "top-level") == "top-level", "unsupported reply or inline format")
    return get_call(payload, binding, operation, repo, "pulls/" + str(num), stage="parent", input=data, subject=parent, number=num)


def normalize(payload, binding, operation, ctx, raw):
    if operation in ("list", "get", "comments"):
        result = finish_or_page(payload, binding, operation, ctx, raw, comment)
        if result.get("complete") and operation == "get":
            matches = [x for x in result["items"] if x["id"] == str(need(ctx.get("selected"), "comment ID is required"))]
            need(len(matches) == 1, "comment ID is missing or ambiguous")
            if ctx.get("expected"):
                expected(matches[0], ctx["expected"])
            result["items"] = matches
        if result.get("call"):
            for field in ("selected", "expected", "subject"):
                result["context"][field] = ctx.get(field)
        else:
            result["subject"] = ctx["subject"]
        return result
    if ctx.get("stage") == "parent":
        parent = pr(raw, ctx["repo"])
        expected(parent, ctx["subject"])
        data = ctx["input"]
        desired = {"body": with_key(data.get("body", ""), data.get("key")), "key": data["key"]}
        listing = data.get("inventory")
        need(listing and listing.get("subject") == ctx["subject"], "comment inventory subject changed")
        items = inventory(listing, binding)
        prior = reusable(items, desired)
        updating = operation == "update" or (operation == "save" and data.get("expected"))
        if prior and not updating:
            return done(binding, [prior], reused=True, subject=ctx["subject"])
        args = {"repo_full_name": ctx["repo"], "comment": desired["body"]}
        if updating:
            item = current(data, binding)
            need(any(x == item for x in items), "updated comment is absent from subject inventory")
            need(item["key"] == data["key"], "comment key changed")
            args["comment_id"] = int(item["id"])
            tool, ident = "github_update_issue_comment", item["id"]
        else:
            args["pr_number"] = ctx["number"]
            tool, ident = "github_add_comment_to_issue", None
        if updating:
            return get_call(payload, binding, operation, ctx["repo"], "issues/comments/" + str(ident), stage="prewrite",
                            arguments=args, tool=tool, expected=data["expected"], desired=desired,
                            comment_id=ident, subject=ctx["subject"], number=ctx["number"])
        return call(payload, tool, args, context(binding, operation, repo=ctx["repo"], stage="write", desired=desired,
                    comment_id=ident, subject=ctx["subject"], number=ctx["number"]))
    if ctx.get("stage") == "prewrite":
        expected(comment(raw, ctx["repo"]), ctx["expected"])
        return call(payload, ctx["tool"], ctx["arguments"], {**ctx, "stage": "write"})
    if ctx.get("stage") == "parent-after":
        expected(pr(raw, ctx["repo"]), ctx["subject"])
        return done(binding, ctx["verified_items"], subject=ctx["subject"])
    if ctx.get("stage") == "write":
        ident = ctx.get("comment_id") or raw.get("id") or raw.get("comment", {}).get("id")
        need(ident, "write result lacks comment ID; reconcile before retrying")
        return get_call(payload, binding, operation, ctx["repo"], "issues/comments/" + str(ident),
                        stage="verify", desired=ctx["desired"], subject=ctx["subject"], comment_id=str(ident))
    item = comment(raw, ctx["repo"])
    need(item["id"] == ctx["comment_id"], "written comment ID changed")
    same(item, ctx["desired"])
    need(item["url"].startswith(ctx["subject"]["url"] + "#"), "written comment subject changed")
    return get_call(payload, binding, operation, ctx["repo"], "pulls/" + ctx["subject"]["url"].rsplit("/", 1)[1],
                    stage="parent-after", subject=ctx["subject"], verified_items=[item])
