import requests
import config
import db
import embeddings

_cached_token = None


def _get_token():
    global _cached_token
    if _cached_token is None:
        resp = requests.post(
            f"{config.PAPERLESS_API_URL}/api/token/",
            data={"username": config.PAPERLESS_USERNAME,
                  "password": config.PAPERLESS_PASSWORD},
            timeout=10,
        )
        resp.raise_for_status()
        _cached_token = resp.json()["token"]
    return _cached_token


def _headers():
    return {"Authorization": f"Token {_get_token()}"}


def get_document_metadata(doc_id):
    resp = requests.get(
        f"{config.PAPERLESS_API_URL}/api/documents/{doc_id}/",
        headers=_headers(), timeout=30,
    )
    resp.raise_for_status()
    doc = resp.json()
    return {
        "id": doc["id"],
        "title": doc.get("title", ""),
        "correspondent": doc.get("correspondent"),
        "document_type": doc.get("document_type"),
        "tags": doc.get("tags", []),
        "created": doc.get("created", ""),
        "content": doc.get("content", "")[:500],
    }


def semantic_search(query, limit=10):
    query_embedding = embeddings.get_embedding(query)
    raw_results = db.search_similar(query_embedding, limit=limit * 2)

    # Deduplicate by document_id, keeping highest similarity
    seen = {}
    for result in raw_results:
        doc_id = result["document_id"]
        if doc_id not in seen or result["similarity"] > seen[doc_id]["similarity"]:
            seen[doc_id] = result

    results = sorted(seen.values(), key=lambda x: x["similarity"], reverse=True)[:limit]

    enriched = []
    for r in results:
        try:
            meta = get_document_metadata(r["document_id"])
            enriched.append({
                **meta,
                "similarity": round(r["similarity"], 4),
                "matched_chunk": r["chunk_text"][:300],
            })
        except Exception as e:
            enriched.append({
                "id": r["document_id"],
                "similarity": round(r["similarity"], 4),
                "matched_chunk": r["chunk_text"][:300],
                "error": str(e),
            })

    return enriched


def keyword_search(query, limit=10):
    resp = requests.get(
        f"{config.PAPERLESS_API_URL}/api/documents/",
        headers=_headers(),
        params={"query": query, "page_size": limit},
        timeout=30,
    )
    resp.raise_for_status()
    return [
        {
            "id": doc["id"],
            "title": doc.get("title", ""),
            "correspondent": doc.get("correspondent"),
            "document_type": doc.get("document_type"),
            "tags": doc.get("tags", []),
            "created": doc.get("created", ""),
        }
        for doc in resp.json().get("results", [])
    ]


def hybrid_search(query, limit=10):
    semantic_results = semantic_search(query, limit=limit)
    keyword_results = keyword_search(query, limit=limit)

    k = 60
    scores = {}
    doc_data = {}

    for rank, result in enumerate(semantic_results):
        doc_id = result["id"]
        scores[doc_id] = scores.get(doc_id, 0) + 1.0 / (k + rank)
        doc_data[doc_id] = result

    for rank, result in enumerate(keyword_results):
        doc_id = result["id"]
        scores[doc_id] = scores.get(doc_id, 0) + 1.0 / (k + rank)
        if doc_id not in doc_data:
            doc_data[doc_id] = result

    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:limit]

    results = []
    for doc_id, score in ranked:
        entry = doc_data[doc_id].copy()
        entry["relevance_score"] = round(score, 6)
        results.append(entry)

    return results


def get_document(doc_id):
    resp = requests.get(
        f"{config.PAPERLESS_API_URL}/api/documents/{doc_id}/",
        headers=_headers(), timeout=30,
    )
    resp.raise_for_status()
    doc = resp.json()
    return {
        "id": doc["id"],
        "title": doc.get("title", ""),
        "correspondent": doc.get("correspondent"),
        "document_type": doc.get("document_type"),
        "tags": doc.get("tags", []),
        "created": doc.get("created", ""),
        "added": doc.get("added", ""),
        "content": doc.get("content", ""),
    }


def _get_paginated_results(url):
    results = []
    while url:
        resp = requests.get(url, headers=_headers(), timeout=30)
        resp.raise_for_status()
        data = resp.json()
        results.extend(data.get("results", []))
        url = data.get("next")
    return results


def list_tags():
    results = _get_paginated_results(
        f"{config.PAPERLESS_API_URL}/api/tags/?page_size=100"
    )
    return [{"id": t["id"], "name": t["name"]} for t in results]


def list_document_types():
    results = _get_paginated_results(
        f"{config.PAPERLESS_API_URL}/api/document_types/?page_size=100"
    )
    return [{"id": t["id"], "name": t["name"]} for t in results]


def search_by_tag(tag_name, limit=20):
    tags = list_tags()
    tag_id = next((t["id"] for t in tags if t["name"].lower() == tag_name.lower()), None)
    if tag_id is None:
        return []

    resp = requests.get(
        f"{config.PAPERLESS_API_URL}/api/documents/",
        headers=_headers(),
        params={"tags__id": tag_id, "page_size": limit},
        timeout=30,
    )
    resp.raise_for_status()
    return [
        {"id": d["id"], "title": d.get("title", ""), "created": d.get("created", "")}
        for d in resp.json().get("results", [])
    ]


def search_by_date_range(start, end, limit=20):
    resp = requests.get(
        f"{config.PAPERLESS_API_URL}/api/documents/",
        headers=_headers(),
        params={"created__date__gte": start, "created__date__lte": end, "page_size": limit},
        timeout=30,
    )
    resp.raise_for_status()
    return [
        {"id": d["id"], "title": d.get("title", ""), "created": d.get("created", "")}
        for d in resp.json().get("results", [])
    ]
