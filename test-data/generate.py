#!/usr/bin/env python3
"""
Generate PDF documents from Jinja2 templates using Chrome headless.

Reads document definitions from data.manifest, renders each through its
Jinja2 template, and converts the resulting HTML to PDF via Chrome's
--print-to-pdf flag.

Usage:
    python3 generate.py              # Generate all PDFs (skip existing)
    python3 generate.py --force      # Regenerate all PDFs
    python3 generate.py --limit 5    # Generate only the first 5 docs
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

from jinja2 import Environment, FileSystemLoader

from data.manifest import DOCUMENTS
from data.farms import FARMS

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates")


def sanitize_filename(title):
    """Convert a document title into a filesystem-safe filename component."""
    name = title.lower()
    name = re.sub(r"[^a-z0-9\s_-]", "", name)
    name = re.sub(r"[\s-]+", "_", name)
    name = name.strip("_")
    return name


def build_pdf_filename(doc):
    """Build the output PDF filename for a document: {id:03d}_{sanitized_title}.pdf"""
    return f"{doc['id']:03d}_{sanitize_filename(doc['title'])}.pdf"


def render_html(env, doc):
    """Render a document's HTML from its Jinja2 template."""
    farm = FARMS.get(doc["farm"], {})

    context = dict(doc)
    context["farm_name"] = farm.get("name", "")
    context["farm_location"] = farm.get("location", "")

    if doc.get("template") == "standard":
        template_name = "standard.html"
    else:
        template_name = doc["template"] + ".html"

    template = env.get_template(template_name)
    return template.render(**context)


def html_to_pdf(html_content, output_path):
    """Convert HTML to PDF using Chrome headless. Returns (success, error_message)."""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".html", delete=False, encoding="utf-8"
    ) as tmp:
        tmp.write(html_content)
        tmp_path = tmp.name

    try:
        result = subprocess.run(
            [
                CHROME,
                "--headless",
                "--disable-gpu",
                "--no-sandbox",
                "--run-all-compositor-stages-before-draw",
                f"--print-to-pdf={output_path}",
                "--no-pdf-header-footer",
                f"file://{tmp_path}",
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            return False, result.stderr.strip()

        if not os.path.exists(output_path):
            return False, "PDF file was not created"

        return True, None

    except subprocess.TimeoutExpired:
        return False, "Chrome timed out after 30 seconds"
    except FileNotFoundError:
        return False, f"Chrome not found at: {CHROME}"
    finally:
        os.unlink(tmp_path)


def main():
    parser = argparse.ArgumentParser(
        description="Generate PDF documents from Jinja2 templates."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate PDFs even if they already exist.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Only generate the first N documents.",
    )
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    env = Environment(
        loader=FileSystemLoader(TEMPLATE_DIR),
        autoescape=False,
    )

    docs = DOCUMENTS
    if args.limit is not None:
        docs = docs[: args.limit]

    total = len(docs)
    generated = 0
    skipped = 0
    errors = 0

    for i, doc in enumerate(docs, 1):
        filename = build_pdf_filename(doc)
        output_path = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(output_path) and not args.force:
            print(f"Skipped  {i}/{total}: {doc['title']} (already exists)")
            skipped += 1
            continue

        try:
            html = render_html(env, doc)
        except Exception as exc:
            print(f"ERROR    {i}/{total}: {doc['title']} -- template render failed: {exc}")
            errors += 1
            continue

        success, error_msg = html_to_pdf(html, output_path)

        if success:
            print(f"Generated {i}/{total}: {doc['title']}")
            generated += 1
        else:
            print(f"ERROR    {i}/{total}: {doc['title']} -- {error_msg}")
            errors += 1

    print()
    print(f"Done. {generated} generated, {skipped} skipped, {errors} errors (out of {total}).")


if __name__ == "__main__":
    main()
