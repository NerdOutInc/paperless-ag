import json
import os
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


APP_DIR = Path(os.environ.get("PAPERLESS_AG_APP_DIR", Path(__file__).resolve().parents[1] / "app"))
sys.path.insert(0, str(APP_DIR))

import search  # noqa: E402
import web_search  # noqa: E402


class FakeResponse:
    def __init__(self, status_code=200, payload=None):
        self.status_code = status_code
        self._payload = payload or {}
        self.text = json.dumps(self._payload)

    def json(self):
        return self._payload

    def raise_for_status(self):
        if self.status_code >= 400:
            import requests

            error = requests.HTTPError(f"HTTP {self.status_code}")
            error.response = self
            raise error


class WebSearchTests(unittest.TestCase):
    def test_clamp_limit_handles_bad_and_out_of_range_values(self):
        self.assertEqual(web_search.clamp_limit(None), 10)
        self.assertEqual(web_search.clamp_limit("nope"), 10)
        self.assertEqual(web_search.clamp_limit("0"), 1)
        self.assertEqual(web_search.clamp_limit("500"), 50)
        self.assertEqual(web_search.clamp_limit("12"), 12)

    @patch("web_search.validate_paperless_session", return_value={"username": "admin"})
    def test_documents_api_rejects_empty_query(self, _validate):
        request = SimpleNamespace(
            headers={"cookie": "sessionid=abc"},
            query_params={"q": "   "},
        )

        response = web_search.documents_api(request)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.body), {"error": "q is required"})

    @patch("web_search.requests.get")
    def test_validate_session_returns_none_for_unauthenticated_cookie(self, get):
        get.return_value = FakeResponse(403, {"detail": "not authenticated"})

        self.assertIsNone(web_search.validate_paperless_session("sessionid=bad"))


class SessionSearchTests(unittest.TestCase):
    @patch("search.embeddings.get_embedding", return_value=[0.1, 0.2])
    @patch("search.db.search_similar")
    @patch("search.paperless_session_request")
    def test_semantic_search_filters_before_returning_chunks(
        self,
        paperless_request,
        search_similar,
        _get_embedding,
    ):
        search_similar.return_value = [
            {
                "document_id": 1,
                "chunk_index": 0,
                "chunk_text": "authorized soil test chunk",
                "similarity": 0.9,
            },
            {
                "document_id": 2,
                "chunk_index": 0,
                "chunk_text": "secret unauthorized chunk",
                "similarity": 0.8,
            },
        ]

        def response_for(method, path, cookie_header, **_kwargs):
            self.assertEqual(method, "GET")
            self.assertEqual(cookie_header, "sessionid=abc")
            if path == "/api/documents/1/":
                return FakeResponse(200, {"id": 1, "title": "Soil Test"})
            if path == "/api/documents/2/":
                return FakeResponse(403, {"detail": "forbidden"})
            return FakeResponse(404, {})

        paperless_request.side_effect = response_for

        results = search.semantic_search_for_session(
            "soil",
            limit=10,
            cookie_header="sessionid=abc",
        )

        self.assertEqual([result["id"] for result in results], [1])
        self.assertEqual(results[0]["matched_chunk"], "authorized soil test chunk")
        self.assertNotIn("secret unauthorized chunk", json.dumps(results))

    @patch("search.keyword_search_for_session")
    @patch("search.semantic_search_for_session")
    def test_hybrid_search_merges_sources_and_scores(self, semantic, keyword):
        semantic.return_value = [
            {"id": 1, "title": "A", "document_url": "/documents/1", "sources": ["semantic"]},
            {"id": 2, "title": "B", "document_url": "/documents/2", "sources": ["semantic"]},
        ]
        keyword.return_value = [
            {"id": 1, "title": "A", "document_url": "/documents/1", "sources": ["keyword"]},
            {"id": 3, "title": "C", "document_url": "/documents/3", "sources": ["keyword"]},
        ]

        results = search.hybrid_search_for_session("crop", limit=10, cookie_header="sessionid=abc")
        by_id = {result["id"]: result for result in results}

        self.assertEqual(by_id[1]["sources"], ["keyword", "semantic"])
        self.assertGreater(by_id[1]["relevance_score"], by_id[2]["relevance_score"])
        self.assertEqual(by_id[3]["document_url"], "/documents/3")


if __name__ == "__main__":
    unittest.main()
