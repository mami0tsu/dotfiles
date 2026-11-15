"""Linear issue comments retain authors and reject unsupported thread writes."""
from mcp import call, context, done, expected, inventory, need, reference, reusable, same, with_key
from linear import FIELDS, current, paged, subject

SKILL = "adapter-linear-comment"
KINDS = {"comment"}


def comment(item, parent):
    ident = need(item.get("id"), "comment ID is missing")
    url = item.get("url") or parent["url"]
    return reference(item, ident, url, item.get("updatedAt"), item.get("body"),
                     comment_id=ident, subject_id=parent["id"], parent_id=item.get("parentId"),
                     root_id=ident if not item.get("parentId") else None,
                     kind="inline" if item.get("quotedText") is not None else "thread" if item.get("parentId") else "top-level",
                     author=item.get("author"), on_behalf_of=item.get("onBehalfOf"), created_at=item.get("createdAt"))


def prepare(payload, binding, operation):
    data = payload.get("input", {})
    parent = subject(binding, data)
    if operation in ("list", "get", "comments"):
        args = {"issueId": parent["id"], "limit": 100}
        return call(payload, "linear_list_comments", args, context(binding, operation, subject=parent, arguments=args,
                    selected=data.get("comment_id") or data.get("id"), expected=data.get("expected")))
    need(operation in ("create", "update", "save", "comment"), "unsupported comment operation")
    need(not data.get("parent_id") and data.get("kind", "top-level") == "top-level", "reply or synced-thread write is unsupported")
    return call(payload, "linear_get_issue", {"id": parent["id"], "fields": FIELDS},
                context(binding, operation, stage="parent", subject=parent, input=data))


def normalize(payload, binding, operation, ctx, raw):
    if ctx.get("stage") == "parent-after":
        actual = {"id": str(raw.get("id")), "url": raw.get("url"), "revision": raw.get("updatedAt")}
        expected(actual, ctx["subject"])
        return done(binding, ctx["verified_items"], subject=ctx["subject"])
    if operation in ("list", "get", "comments") or ctx.get("stage") == "verify":
        result = paged(payload, binding, operation, ctx, raw, "comments", lambda x: comment(x, ctx["subject"]),
                       "linear_list_comments", ctx["arguments"])
        if not result.get("complete"):
            return result
        items = result["items"]
        by_id = {x["id"]: x for x in items}
        for item in items:
            seen = set()
            node = item
            while node["parent_id"]:
                need(node["id"] not in seen and node["parent_id"] in by_id, "comment root is missing or cyclic")
                seen.add(node["id"])
                node = by_id[node["parent_id"]]
            item["root_id"] = node["id"]
        if operation == "get" or ctx.get("stage") == "verify":
            ident = str(need(ctx.get("selected"), "comment ID is required"))
            items = [x for x in items if x["id"] == ident]
            need(len(items) == 1, "comment ID is missing or ambiguous")
            if ctx.get("expected"):
                expected(items[0], ctx["expected"])
            if ctx.get("desired"):
                same(items[0], ctx["desired"])
            result["items"] = items
        result["subject"] = ctx["subject"]
        if ctx.get("stage") == "verify":
            return call(payload, "linear_get_issue", {"id": ctx["subject"]["id"], "fields": FIELDS},
                        context(binding, operation, stage="parent-after", subject=ctx["subject"], verified_items=result["items"]))
        return result
    if ctx.get("stage") == "parent":
        actual = {"id": str(raw.get("id")), "url": raw.get("url"), "revision": raw.get("updatedAt")}
        expected(actual, ctx["subject"])
        data = ctx["input"]
        desired = {"body": with_key(data.get("body", ""), data.get("key")), "key": data["key"]}
        listing = data.get("inventory")
        need(listing and listing.get("subject") == ctx["subject"], "comment inventory subject changed")
        items = inventory(listing, binding)
        prior = reusable(items, desired)
        updating = operation == "update" or (operation in ("save", "comment") and data.get("expected"))
        if prior and not updating:
            return done(binding, [prior], reused=True, subject=ctx["subject"])
        args = {"body": desired["body"]}
        if updating:
            item = current(data, binding)
            need(item.get("kind") == "top-level" and not item.get("parent_id"), "only top-level comment updates are supported")
            need(any(x == item for x in items), "updated comment is absent from subject inventory")
            need(item["key"] == data["key"], "comment key changed")
            args["id"] = item["id"]
        else:
            args["issueId"] = ctx["subject"]["id"]
        return call(payload, "linear_save_comment", args, context(binding, operation, stage="write", subject=ctx["subject"], desired=desired))
    ident = need(raw.get("id"), "saved comment ID is missing; reconcile before retrying")
    args = {"issueId": ctx["subject"]["id"], "limit": 100}
    return call(payload, "linear_list_comments", args, context(binding, operation, stage="verify", subject=ctx["subject"],
                desired=ctx["desired"], selected=ident, arguments=args))
