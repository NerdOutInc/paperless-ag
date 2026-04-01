import threading
import requests
import config


_token = None
_token_lock = threading.Lock()


def _authenticate():
    resp = requests.post(
        f"{config.PAPERLESS_API_URL}/api/token/",
        data={"username": config.PAPERLESS_USERNAME,
              "password": config.PAPERLESS_PASSWORD},
        timeout=10,
    )
    resp.raise_for_status()
    return resp.json()["token"]


def get_token():
    global _token
    if _token is not None:
        return _token
    with _token_lock:
        if _token is None:
            _token = _authenticate()
    return _token


def clear_token():
    global _token
    with _token_lock:
        _token = None


def headers():
    return {"Authorization": f"Token {get_token()}"}


def api_request(method, url, retry_on_401=True, **kwargs):
    """Make an authenticated API request with automatic re-auth on 401."""
    kwargs.setdefault("timeout", 30)
    resp = requests.request(method, url, headers=headers(), **kwargs)
    if resp.status_code == 401 and retry_on_401:
        clear_token()
        resp = requests.request(method, url, headers=headers(), **kwargs)
    resp.raise_for_status()
    return resp
