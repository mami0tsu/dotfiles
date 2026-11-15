"""Linear issue calls preserve team, relations, and full-page inventories."""
from mcp import call, context, done, inventory, need, resource_module, reusable, same, with_key
from linear import FIELDS, LIST_FIELDS, current, issue, paged, team

SKILL = "adapter-linear-issue"
KINDS = {"collection"}


def prepare(payload, binding, operation):
    if operation in ("comments", "comment"):
        return resource_module("adapter-linear-comment").prepare(payload, binding, operation)
    data = payload.get("input", {})
    team_id = team(binding, data)
    if operation == "list":
        args = {"team": team_id, "includeArchived": True, "fields": LIST_FIELDS, "limit": 100}
        return call(payload, "linear_list_issues", args, context(binding, operation, team_id=team_id, arguments=args))
    if operation in ("get", "decision"):
        return call(payload, "linear_get_issue", {"id": need(data.get("id"), "issue ID is required"), "fields": FIELDS},
                    context(binding, operation, team_id=team_id, expected=data.get("expected"), requested_id=data["id"]))
    need(operation in ("create", "update"), "unsupported issue operation")
    need(binding["role"] == "tasks" or operation == "create", "idea decisions cannot be written by this adapter")
    desired = {"body": with_key(data.get("body", ""), data.get("key")), "key": data["key"],
               "title": need(data.get("title"), "title is required")}
    args = {"description": desired["body"], "title": desired["title"]}
    if operation == "create":
        prior = reusable(inventory(data.get("inventory"), binding), desired)
        if prior:
            return done(binding, [prior], reused=True)
        args["team"] = team_id
    else:
        prior = current(data, binding)
        need(prior["key"] == data["key"], "stable key changed")
        args["id"] = prior["id"]
        need(prior["team_id"] == team_id, "issue team changed")
    relations = data.get("relations", {})
    need(not set(relations) - {"parentId", "blockedBy", "blocks"}, "unsupported relation update")
    if operation == "create":
        args.update(relations)
    else:
        if "parentId" in relations:
            args["parentId"] = relations["parentId"]
        for name, remove in (("blocks", "removeBlocks"), ("blockedBy", "removeBlockedBy")):
            if name in relations:
                known = prior.get("relations")
                need(isinstance(known, dict) and isinstance(known.get(name), list), "current relation set is missing")
                old = {x["id"] if isinstance(x, dict) else x for x in known[name]}
                new = relations[name]
                need(isinstance(new, list) and all(isinstance(x, str) for x in new), "relation IDs must be a list")
                if set(new) - old:
                    args[name] = sorted(set(new) - old)
                if old - set(new):
                    args[remove] = sorted(old - set(new))
    if data.get("state") is not None:
        states = data.get("verified_states", [])
        need(data["state"] in states, "state must be resolved from current team statuses")
        args["state"] = data["state"]
        desired["state"] = data["state"]
    if operation == "update":
        return call(payload, "linear_get_issue", {"id": args["id"], "fields": FIELDS},
                    context(binding, operation, team_id=team_id, stage="prewrite", desired=desired, arguments=args, expected=data["expected"]))
    return call(payload, "linear_save_issue", args, context(binding, operation, team_id=team_id, stage="write", desired=desired))


def normalize(payload, binding, operation, ctx, raw):
    if operation == "decision":
        if ctx.get("stage") != "decision-comments":
            item = issue(raw, ctx["team_id"])
            need(ctx["requested_id"] in (item["id"], item.get("uuid"), item["url"]), "returned idea ID changed")
            if ctx.get("expected"):
                from mcp import expected
                expected(item, ctx["expected"])
            args = {"issueId": item["id"], "limit": 100}
            return call(payload, "linear_list_comments", args, {**ctx, "stage": "decision-comments", "decision_item": item, "arguments": args})
        comments = resource_module("adapter-linear-comment")
        result = paged(payload, binding, operation, ctx, raw, "comments", lambda x: comments.comment(x, ctx["decision_item"]),
                       "linear_list_comments", ctx["arguments"])
        if result.get("complete"):
            from evidence import decision_evidence
            result["evidence"] = decision_evidence(result["items"], ctx["decision_item"])
            result["items"] = [ctx["decision_item"]]
        return result
    if ctx.get("stage") == "prewrite":
        from mcp import expected
        expected(issue(raw, ctx["team_id"]), ctx["expected"])
        return call(payload, "linear_save_issue", ctx["arguments"], {**ctx, "stage": "write"})
    if operation in ("comments", "comment"):
        return resource_module("adapter-linear-comment").normalize(payload, binding, operation, ctx, raw)
    if operation == "list":
        need(isinstance(raw, dict) and isinstance(raw.get("issues"), list), "issue collection is missing")
        need(all(x.get("teamId") for x in raw["issues"]), "listed issue team is missing")
        raw = {**raw, "issues": [x for x in raw["issues"] if x["teamId"] == ctx["team_id"]]}
        return paged(payload, binding, operation, ctx, raw, "issues", lambda x: issue(x, ctx["team_id"]), "linear_list_issues", ctx["arguments"])
    if ctx.get("stage") == "write":
        ident = need(raw.get("id"), "saved issue ID is missing; reconcile before retrying")
        return call(payload, "linear_get_issue", {"id": ident, "fields": FIELDS},
                    context(binding, operation, team_id=ctx["team_id"], stage="verify", desired=ctx["desired"]))
    item = issue(raw, ctx["team_id"])
    if ctx.get("requested_id"):
        need(ctx["requested_id"] in (item["id"], item.get("uuid"), item["url"]), "returned issue ID changed")
    if ctx.get("desired"):
        same(item, ctx["desired"])
    if ctx.get("expected"):
        from mcp import expected
        expected(item, ctx["expected"])
    return done(binding, [item])
