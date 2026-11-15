"""Issue calls retain full-page inventories and human decision evidence."""
from mcp import call, context, done, inventory, need, reusable, with_key
from github import preflight, resume_repository, current, finish_or_page, get_call, issue, number, repository, verify_or_done

SKILL = "adapter-github-issue"
KINDS = {"collection"}


def prepare(payload, binding, operation):
    pending = preflight(payload, binding, operation)
    if pending:
        return pending
    if operation in ("comments", "comment"):
        from mcp import resource_module
        return resource_module("adapter-github-comment").prepare(payload, binding, operation)
    data = payload.get("input", {})
    repo = repository(binding, data)
    if operation == "list":
        collection = "issues?state=all&per_page=100"
        return get_call(payload, binding, operation, repo, collection + "&page=1", page=1, collection=collection)
    if operation in ("get", "decision"):
        return get_call(payload, binding, operation, repo, "issues/" + str(number(data, repo, "issues")), expected=data.get("expected"), identity={k: data[k] for k in ("id", "url") if data.get(k)})
    need(operation in ("create", "update"), "unsupported issue operation")
    need(binding["role"] == "tasks" or operation == "create", "idea decisions cannot be written by this adapter")
    body = with_key(data.get("body", ""), data.get("key"))
    desired = {"key": data["key"], "body": body, "title": need(data.get("title"), "title is required")}
    args = {"repository_full_name": repo, "title": desired["title"], "body": body}
    if operation == "create":
        prior = reusable(inventory(data.get("inventory"), binding), desired)
        if prior:
            return done(binding, [prior], reused=True)
        tool = "github_create_issue"
        verify_path = None
    else:
        prior = current(data, binding)
        need(prior["key"] == data["key"], "stable key changed")
        args["issue_number"] = prior["number"]
        tool = "github_update_issue"
        verify_path = "issues/" + str(prior["number"])
    if args.get("issue_number"):
        return get_call(payload, binding, operation, repo, verify_path, stage="prewrite", arguments=args,
                        tool=tool, desired=desired, expected=data["expected"], verify_path=verify_path)
    return call(payload, tool, args, context(binding, operation, repo=repo, stage="write", desired=desired, verify_path=verify_path))


def normalize(payload, binding, operation, ctx, raw):
    if ctx.get("stage") == "resolve-repository":
        from mcp import resource_module
        return resume_repository(resource_module(SKILL), payload, binding, operation, ctx, raw)
    if operation == "decision":
        if ctx.get("stage") != "decision-comments":
            item = issue(raw, ctx["repo"])
            need(item["number"] == int(ctx["path"].rsplit("/", 1)[1]), "returned idea number changed")
            for field, value in ctx.get("identity", {}).items():
                need(str(item.get(field)) == str(value), "returned idea identity changed")
            if ctx.get("expected"):
                from mcp import expected
                expected(item, ctx["expected"])
            collection = "issues/" + str(item["number"]) + "/comments?per_page=100"
            return get_call(payload, binding, operation, ctx["repo"], collection + "&page=1", stage="decision-comments",
                            collection=collection, page=1, decision_item=item)
        from mcp import resource_module
        result = finish_or_page(payload, binding, operation, ctx, raw, resource_module("adapter-github-comment").comment)
        if result.get("complete"):
            from evidence import decision_evidence
            result["evidence"] = decision_evidence(result["items"], ctx["decision_item"])
            result["items"] = [ctx["decision_item"]]
        return result
    if ctx.get("stage") == "prewrite":
        from mcp import expected
        expected(issue(raw, ctx["repo"]), ctx["expected"])
        return call(payload, ctx["tool"], ctx["arguments"], {**ctx, "stage": "write"})
    if operation in ("comments", "comment"):
        from mcp import resource_module
        return resource_module("adapter-github-comment").normalize(payload, binding, operation, ctx, raw)
    if operation == "list":
        return finish_or_page(payload, binding, operation, ctx, raw, issue, lambda x: "pull_request" not in x)
    if ctx.get("stage") == "write" and not ctx.get("verify_path"):
        item = raw.get("issue", raw)
        ctx["verify_path"] = "issues/" + str(need(item.get("issue_number") or item.get("number"), "created issue number is missing"))
    return verify_or_done(payload, binding, operation, ctx, raw, issue)
