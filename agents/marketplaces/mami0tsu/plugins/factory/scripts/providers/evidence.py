"""Normalize adapter decision sources without deciding adoption."""
from mcp import need

def decision_evidence(items, subject):
    result = []
    ref = {k: subject[k] for k in ("id", "url", "revision")}
    for item in items:
        author = item.get("author")
        need(isinstance(author, dict) and author.get("id"), "decision source author ID is missing")
        need(item.get("body") and item.get("revision"), "decision source text or timestamp is missing")
        source = {**item, "actor": str(author["id"]), "at": item.get("created_at") or item["revision"], "subject": ref, "scope": "read-target"}
        if source.get("created_at") is None:
            source.pop("created_at", None)
        result.append(source)
    return result
