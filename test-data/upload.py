#!/usr/bin/env python3
"""
Upload generated PDFs to Paperless NGX via its REST API.

Creates document types, correspondents, and tags in Paperless, then uploads
each PDF with the correct metadata. Idempotent -- existing items are reused.

Usage:
    python3 upload.py                          # Upload all PDFs
    python3 upload.py --limit 5                # Upload only the first 5
    python3 upload.py --url http://host:8000   # Custom Paperless URL
    python3 upload.py --skip-setup             # Skip creating types/correspondents/tags
    python3 upload.py --dry-run                # Show what would be uploaded
"""

import argparse
import os
import re
import sys

import requests

from data.manifest import DOCUMENTS
from data.farms import DOCUMENT_TYPES, CORRESPONDENTS, TAGS

TAG_COLORS = {
    # Farm names - bold, distinct
    "horob-family-farms": ("#2d5016", "#ffffff"),
    "nerd-out-ranch":     ("#8b4513", "#ffffff"),
    "pattison-acres":     ("#1a3a5c", "#ffffff"),
    # Years - muted tones
    "2023": ("#5b7065", "#ffffff"),
    "2024": ("#4a6670", "#ffffff"),
    "2025": ("#6b5b73", "#ffffff"),
    "2026": ("#3d6b5e", "#ffffff"),
    # Crops - greens/golds
    "corn":     ("#d4a017", "#000000"),
    "soybeans": ("#7a9a47", "#ffffff"),
    "wheat":    ("#c8a951", "#000000"),
    # Livestock
    "cattle":      ("#8b3a3a", "#ffffff"),
    "breeding":    ("#a0522d", "#ffffff"),
    "grazing":     ("#6b8e23", "#ffffff"),
    "hay":         ("#9acd32", "#000000"),
    "vaccination": ("#5f9ea0", "#ffffff"),
    # Inputs/chemicals
    "nitrogen":   ("#2e8b57", "#ffffff"),
    "phosphorus": ("#c97038", "#ffffff"),
    "herbicide":  ("#556b2f", "#ffffff"),
    "fungicide":  ("#8fbc8f", "#000000"),
    # Business/admin
    "insurance": ("#708090", "#ffffff"),
    "lease":     ("#5d4e37", "#ffffff"),
    "tax":       ("#4682b4", "#ffffff"),
    "equipment": ("#b8860b", "#ffffff"),
}

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")


def sanitize_filename(title):
    """Convert a document title into a filesystem-safe filename component."""
    name = title.lower()
    name = re.sub(r"[^a-z0-9\s_-]", "", name)
    name = re.sub(r"[\s-]+", "_", name)
    name = name.strip("_")
    return name


def build_pdf_filename(doc):
    """Build the expected PDF filename for a document."""
    return f"{doc['id']:03d}_{sanitize_filename(doc['title'])}.pdf"


def get_auth_token(base_url, username, password):
    """Authenticate with Paperless and return the API token."""
    resp = requests.post(
        f"{base_url}/api/token/",
        data={"username": username, "password": password},
    )
    resp.raise_for_status()
    return resp.json()["token"]


def get_all_pages(url, headers):
    """Fetch all pages of a paginated Paperless API response."""
    results = []
    while url:
        resp = requests.get(url, headers=headers)
        resp.raise_for_status()
        body = resp.json()
        results.extend(body.get("results", []))
        url = body.get("next")
    return results


def ensure_items(base_url, headers, endpoint, names):
    """
    Ensure all names exist in the given API endpoint.
    Returns a dict mapping name -> id.
    """
    url = f"{base_url}/api/{endpoint}/"
    existing = get_all_pages(url, headers)
    lookup = {item["name"]: item["id"] for item in existing}

    for name in names:
        if name in lookup:
            continue
        try:
            resp = requests.post(url, headers=headers, json={"name": name})
            resp.raise_for_status()
            item = resp.json()
            lookup[item["name"]] = item["id"]
            print(f"  Created {endpoint[:-1]}: {name}")
        except requests.RequestException as exc:
            print(f"  ERROR creating {endpoint[:-1]} '{name}': {exc}")

    return lookup


def set_tag_colors(base_url, headers, tag_lookup):
    """Update tag colors to the curated palette."""
    for name, tag_id in tag_lookup.items():
        if name not in TAG_COLORS:
            continue
        bg, text = TAG_COLORS[name]
        try:
            resp = requests.patch(
                f"{base_url}/api/tags/{tag_id}/",
                headers={**headers, "Content-Type": "application/json"},
                json={"color": bg, "text_color": text},
            )
            resp.raise_for_status()
        except requests.RequestException as exc:
            print(f"  WARNING: could not set color for tag '{name}': {exc}")


def setup_metadata(base_url, headers):
    """Create document types, correspondents, and tags. Returns lookup dicts."""
    print("Setting up document types...")
    type_lookup = ensure_items(base_url, headers, "document_types", DOCUMENT_TYPES)

    print("Setting up correspondents...")
    corr_lookup = ensure_items(base_url, headers, "correspondents", CORRESPONDENTS)

    print("Setting up tags...")
    tag_lookup = ensure_items(base_url, headers, "tags", TAGS)

    print("Setting tag colors...")
    set_tag_colors(base_url, headers, tag_lookup)

    print(
        f"Setup complete: {len(type_lookup)} types, "
        f"{len(corr_lookup)} correspondents, {len(tag_lookup)} tags."
    )
    print()

    return type_lookup, corr_lookup, tag_lookup


def load_existing_metadata(base_url, headers):
    """Load existing document types, correspondents, and tags without creating."""
    print("Loading existing metadata...")

    existing_types = get_all_pages(f"{base_url}/api/document_types/", headers)
    type_lookup = {item["name"]: item["id"] for item in existing_types}

    existing_corr = get_all_pages(f"{base_url}/api/correspondents/", headers)
    corr_lookup = {item["name"]: item["id"] for item in existing_corr}

    existing_tags = get_all_pages(f"{base_url}/api/tags/", headers)
    tag_lookup = {item["name"]: item["id"] for item in existing_tags}

    print(
        f"Loaded: {len(type_lookup)} types, "
        f"{len(corr_lookup)} correspondents, {len(tag_lookup)} tags."
    )
    print()

    return type_lookup, corr_lookup, tag_lookup


def upload_document(base_url, headers, doc, pdf_path, type_lookup, corr_lookup, tag_lookup):
    """Upload a single PDF to Paperless. Returns (success, error_message)."""
    url = f"{base_url}/api/documents/post_document/"

    data = {}

    if doc.get("title"):
        data["title"] = doc["title"]

    if doc.get("correspondent") and doc["correspondent"] in corr_lookup:
        data["correspondent"] = corr_lookup[doc["correspondent"]]

    if doc.get("type") and doc["type"] in type_lookup:
        data["document_type"] = type_lookup[doc["type"]]

    if doc.get("created_date"):
        data["created"] = doc["created_date"]

    # Tags must be sent as repeated form fields, not comma-separated
    tag_ids = []
    if doc.get("tags"):
        for tag_name in doc["tags"]:
            if tag_name in tag_lookup:
                tag_ids.append(tag_lookup[tag_name])

    try:
        with open(pdf_path, "rb") as f:
            files = {"document": (os.path.basename(pdf_path), f, "application/pdf")}
            # Build multipart form with repeated 'tags' fields
            form_data = list(data.items())
            for tid in tag_ids:
                form_data.append(("tags", tid))
            resp = requests.post(url, headers=headers, data=form_data, files=files)
            resp.raise_for_status()
        return True, None
    except requests.RequestException as exc:
        error_detail = str(exc)
        try:
            error_detail = resp.text[:200]
        except Exception:
            pass
        return False, error_detail


def main():
    parser = argparse.ArgumentParser(
        description="Upload generated PDFs to Paperless NGX."
    )
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="Paperless NGX base URL (default: http://localhost:8000).",
    )
    parser.add_argument(
        "--username",
        default="admin",
        help="Paperless username (default: admin).",
    )
    parser.add_argument(
        "--password",
        default="admin",
        help="Paperless password (default: admin).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Only upload the first N documents.",
    )
    parser.add_argument(
        "--skip-setup",
        action="store_true",
        help="Skip creating document types, correspondents, and tags.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be uploaded without uploading.",
    )
    args = parser.parse_args()

    base_url = args.url.rstrip("/")

    # Authenticate
    if not args.dry_run:
        print(f"Authenticating with {base_url}...")
        try:
            token = get_auth_token(base_url, args.username, args.password)
        except requests.RequestException as exc:
            print(f"Authentication failed: {exc}")
            sys.exit(1)

        headers = {"Authorization": f"Token {token}"}
        print("Authenticated.")
        print()
    else:
        headers = {}
        token = None

    # Set up metadata
    if args.dry_run:
        type_lookup = {name: f"<{name}>" for name in DOCUMENT_TYPES}
        corr_lookup = {name: f"<{name}>" for name in CORRESPONDENTS}
        tag_lookup = {name: f"<{name}>" for name in TAGS}
    elif args.skip_setup:
        type_lookup, corr_lookup, tag_lookup = load_existing_metadata(base_url, headers)
    else:
        type_lookup, corr_lookup, tag_lookup = setup_metadata(base_url, headers)

    # Upload documents
    docs = DOCUMENTS
    if args.limit is not None:
        docs = docs[: args.limit]

    total = len(docs)
    uploaded = 0
    error_count = 0
    missing = 0

    for i, doc in enumerate(docs, 1):
        filename = build_pdf_filename(doc)
        pdf_path = os.path.join(OUTPUT_DIR, filename)

        if not os.path.exists(pdf_path):
            print(f"MISSING  {i}/{total}: {doc['title']} -- {filename} not found")
            missing += 1
            continue

        if args.dry_run:
            tag_names = ", ".join(doc.get("tags", []))
            print(
                f"Would upload {i}/{total}: {doc['title']}\n"
                f"    File: {filename}\n"
                f"    Type: {doc.get('type', 'N/A')}\n"
                f"    Correspondent: {doc.get('correspondent', 'N/A')}\n"
                f"    Tags: {tag_names}\n"
                f"    Created: {doc.get('created_date', 'N/A')}"
            )
            uploaded += 1
            continue

        success, error_msg = upload_document(
            base_url, headers, doc, pdf_path, type_lookup, corr_lookup, tag_lookup
        )

        if success:
            print(f"Uploaded {i}/{total}: {doc['title']}")
            uploaded += 1
        else:
            print(f"ERROR    {i}/{total}: {doc['title']} -- {error_msg}")
            error_count += 1

    print()
    action = "Would upload" if args.dry_run else "Uploaded"
    print(
        f"Done. {action} {uploaded}/{total} documents, "
        f"{error_count} errors, {missing} missing PDFs."
    )


if __name__ == "__main__":
    main()
