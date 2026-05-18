from pathlib import Path
from urllib.parse import quote

import requests
from starlette.responses import HTMLResponse, JSONResponse, RedirectResponse
from starlette.routing import Mount, Route
from starlette.staticfiles import StaticFiles

import config
import search


STATIC_DIR = Path(__file__).with_name("static").joinpath("search")
MAX_SEARCH_LIMIT = 50
DEFAULT_SEARCH_LIMIT = 10


def clamp_limit(raw_limit, default=DEFAULT_SEARCH_LIMIT, max_limit=MAX_SEARCH_LIMIT):
    try:
        value = int(raw_limit)
    except (TypeError, ValueError):
        return default
    return max(1, min(value, max_limit))


def cookie_header_from_request(request):
    return request.headers.get("cookie", "")


def login_redirect_for(request):
    target = request.url.path
    if request.url.query:
        target = f"{target}?{request.url.query}"
    return RedirectResponse(
        f"/accounts/login/?next={quote(target, safe='/?=&')}",
        status_code=302,
    )


def validate_paperless_session(cookie_header):
    if not cookie_header:
        return None

    response = requests.get(
        f"{config.PAPERLESS_API_URL}/api/profile/",
        headers={
            "Accept": "application/json",
            "Cookie": cookie_header,
        },
        timeout=10,
    )
    if response.status_code in (401, 403):
        return None
    response.raise_for_status()

    try:
        return response.json()
    except ValueError:
        return None


def public_profile(profile):
    return {
        "id": profile.get("id"),
        "username": profile.get("username", ""),
        "email": profile.get("email", ""),
        "first_name": profile.get("first_name", ""),
        "last_name": profile.get("last_name", ""),
    }


def search_page(request):
    profile = validate_paperless_session(cookie_header_from_request(request))
    if profile is None:
        return login_redirect_for(request)

    index_path = STATIC_DIR / "index.html"
    return HTMLResponse(
        index_path.read_text(encoding="utf-8"),
        headers={"Cache-Control": "no-store"},
    )


def profile_api(request):
    profile = validate_paperless_session(cookie_header_from_request(request))
    if profile is None:
        return JSONResponse(
            {"error": "not_authenticated"},
            status_code=401,
            headers={"Cache-Control": "no-store"},
        )
    return JSONResponse(
        {"profile": public_profile(profile)},
        headers={"Cache-Control": "no-store"},
    )


def documents_api(request):
    cookie_header = cookie_header_from_request(request)
    if validate_paperless_session(cookie_header) is None:
        return JSONResponse(
            {"error": "not_authenticated"},
            status_code=401,
            headers={"Cache-Control": "no-store"},
        )

    query = request.query_params.get("q", "").strip()
    if not query:
        return JSONResponse(
            {"error": "q is required"},
            status_code=400,
            headers={"Cache-Control": "no-store"},
        )

    limit = clamp_limit(request.query_params.get("limit"))
    try:
        results = search.hybrid_search_for_session(query, limit, cookie_header)
    except requests.HTTPError as exc:
        status_code = exc.response.status_code if exc.response is not None else 502
        if status_code in (401, 403):
            return JSONResponse(
                {"error": "not_authenticated"},
                status_code=401,
                headers={"Cache-Control": "no-store"},
            )
        print(f"Search API upstream error: {exc}")
        return JSONResponse(
            {"error": "paperless_api_error"},
            status_code=502,
            headers={"Cache-Control": "no-store"},
        )
    except Exception as exc:
        print(f"Search API error: {exc}")
        return JSONResponse(
            {"error": "search_failed"},
            status_code=500,
            headers={"Cache-Control": "no-store"},
        )

    return JSONResponse(
        {
            "query": query,
            "limit": limit,
            "count": len(results),
            "results": results,
        },
        headers={"Cache-Control": "no-store"},
    )


def routes():
    return [
        Route("/search", search_page, methods=["GET"]),
        Route("/search/", search_page, methods=["GET"]),
        Route("/search/api/me", profile_api, methods=["GET"]),
        Route("/search/api/documents", documents_api, methods=["GET"]),
        Mount(
            "/search/static",
            app=StaticFiles(directory=str(STATIC_DIR)),
            name="search-static",
        ),
    ]
