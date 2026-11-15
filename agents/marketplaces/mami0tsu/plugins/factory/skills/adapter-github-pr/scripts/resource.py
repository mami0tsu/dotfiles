"""Draft PR operations end at a review handoff."""
from mcp import call, context, done, inventory, need, reusable, with_key
from github import preflight, resume_repository, current, finish_or_page, get_call, number, pr, repository, verify_or_done

SKILL = "adapter-github-pr"
KINDS = {"change"}


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
        collection = "pulls?state=all&per_page=100"
        return get_call(payload, binding, operation, repo, collection + "&page=1", page=1, collection=collection)
    if operation == "get":
        return get_call(payload, binding, operation, repo, "pulls/" + str(number(data, repo, "pull")), expected=data.get("expected"), identity={k: data[k] for k in ("id", "url") if data.get(k)})
    if operation == "request-review":
        need(binding["role"] == "changes", "review requests require changes")
        from common import load_config
        cfg = load_config(payload)
        reviewers = cfg["reviewers"].get(data.get("worker", "implement"), cfg["reviewers"]["default"])
        import re
        need(all(isinstance(x, str) and re.fullmatch(r"[A-Za-z0-9-]+", x) for x in reviewers), "reviewers must be verified GitHub usernames")
        ref = data.get("expected") or {k: data.get(k) for k in ("id", "url", "revision")}
        return get_call(payload, binding, operation, repo, "pulls/" + str(number(data, repo, "pull")),
                        stage="review-check", expected=ref, reviewers=reviewers)
    need(operation in ("create", "update", "save"), "unsupported PR operation")
    need(data.get("task", {}).get("id") and data["task"].get("url"), "one task reference is required")
    body = with_key(data.get("body", ""), data.get("key"))
    need(data["task"]["url"] in body, "PR body must retain the task URL")
    desired = {"key": data["key"], "body": body, "title": need(data.get("title"), "title is required"),
               "base": binding["target"]["base"], "head": need(data.get("head"), "explicit pushed head branch is required"),
               "revision": need(data.get("revision"), "verified pushed head SHA is required")}
    recorded = data.get("task", {}).get("change")
    if recorded:
        need(recorded.get("repository") == repo and recorded.get("key") == data["key"], "task already has another repository or PR")
    args = {"repository_full_name": repo, "title": desired["title"], "body": body}
    if operation == "create" or (operation == "save" and not data.get("expected")):
        items = inventory(data.get("inventory"), binding)
        task_matches = [x for x in items if data["task"]["url"] in x.get("body", "")]
        need(all(x.get("key") == data["key"] for x in task_matches), "task already has a different PR")
        prior = reusable(items, desired)
        if prior:
            return done(binding, [prior], reused=True)
        need(not recorded, "recorded PR is missing from inventory")
        args.update(base=desired["base"], head=desired["head"], draft=True)
        tool, verify_path = "github_create_pull_request", None
        desired["draft"] = True
    else:
        prior = current(data, binding)
        need(prior["key"] == data["key"] and prior["head"] == desired["head"] and prior["base"] == desired["base"], "PR identity or branches changed")
        need(not recorded or recorded.get("url") == prior["url"], "task has another PR")
        args["pr_number"] = prior["number"]
        tool, verify_path = "github_update_pull_request", "pulls/" + str(prior["number"])
    if args.get("pr_number"):
        return get_call(payload, binding, operation, repo, verify_path, stage="prewrite", arguments=args,
                        tool=tool, desired=desired, expected=data["expected"], verify_path=verify_path)
    return call(payload, tool, args, context(binding, operation, repo=repo, stage="write", verify_path=verify_path, desired=desired))


def normalize(payload, binding, operation, ctx, raw):
    if operation == "request-review" and ctx.get("stage") != "resolve-repository":
        from mcp import expected
        if ctx.get("stage") == "review-write":
            return get_call(payload, binding, operation, ctx["repo"], ctx["path"], stage="review-verify", expected=ctx["expected"], reviewers=ctx["reviewers"])
        item = pr(raw, ctx["repo"])
        expected(item, ctx["expected"])
        if ctx.get("stage") == "review-verify":
            need(set(ctx["reviewers"]) <= set(item["requested_reviewers"]), "requested reviewers were not confirmed")
            return done(binding, [item], review_requested=ctx["reviewers"])
        missing = sorted(set(ctx["reviewers"]) - set(item["requested_reviewers"]))
        if not missing:
            return done(binding, [item], review_requested=ctx["reviewers"])
        need(item.get("draft") is False, "formal review requests require a human to make the PR ready")
        need(item.get("state") == "open", "review requests require an open PR")
        return call(payload, "github_request_pull_request_reviewers", {"repository_full_name": ctx["repo"], "pr_number": item["number"], "reviewers": missing},
                    {**ctx, "stage": "review-write"})
    if ctx.get("stage") == "resolve-repository":
        from mcp import resource_module
        return resume_repository(resource_module(SKILL), payload, binding, operation, ctx, raw)
    if ctx.get("stage") == "prewrite":
        from mcp import expected
        expected(pr(raw, ctx["repo"]), ctx["expected"])
        return call(payload, ctx["tool"], ctx["arguments"], {**ctx, "stage": "write"})
    if operation in ("comments", "comment"):
        from mcp import resource_module
        return resource_module("adapter-github-comment").normalize(payload, binding, operation, ctx, raw)
    if operation == "list":
        return finish_or_page(payload, binding, operation, ctx, raw, pr)
    if ctx.get("stage") == "write" and not ctx.get("verify_path"):
        ctx["verify_path"] = "pulls/" + str(need(raw.get("number"), "created PR number is missing"))
    return verify_or_done(payload, binding, operation, ctx, raw, pr)
