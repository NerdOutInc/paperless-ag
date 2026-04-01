import json
from mcp.server.fastmcp import FastMCP
import search
import db

mcp = FastMCP("Paperless Ag", json_response=True)


@mcp.tool()
def search_documents(query: str, limit: int = 10) -> str:
    """Search farm documents using hybrid semantic and keyword search.

    Combines vector similarity search (finds conceptually related documents)
    with keyword search (finds exact term matches). Use this for queries like
    "find everything related to nitrogen management" or "crop insurance documents".

    Args:
        query: Natural language search query
        limit: Maximum number of results (default 10)
    """
    results = search.hybrid_search(query, limit=limit)
    return json.dumps(results, indent=2, default=str)


@mcp.tool()
def get_document(document_id: int) -> str:
    """Get full details and content for a specific document.

    Use this after searching to read the complete text of a document.

    Args:
        document_id: The Paperless document ID
    """
    doc = search.get_document(document_id)
    return json.dumps(doc, indent=2, default=str)


@mcp.tool()
def list_tags() -> str:
    """List all tags in the document management system.

    Returns all available tags. Useful for understanding how documents
    are organized and for filtering searches.
    """
    tags = search.list_tags()
    return json.dumps(tags, indent=2)


@mcp.tool()
def list_document_types() -> str:
    """List all document types in the system.

    Returns categories like Soil Test Report, Crop Insurance Policy, etc.
    """
    types = search.list_document_types()
    return json.dumps(types, indent=2)


@mcp.tool()
def search_by_tag(tag: str, limit: int = 20) -> str:
    """Find all documents with a specific tag.

    Args:
        tag: Tag name (e.g., horob-family-farms, corn, nitrogen)
        limit: Maximum number of results
    """
    results = search.search_by_tag(tag, limit=limit)
    return json.dumps(results, indent=2, default=str)


@mcp.tool()
def search_by_date_range(start: str, end: str, limit: int = 20) -> str:
    """Find documents within a date range.

    Args:
        start: Start date in YYYY-MM-DD format
        end: End date in YYYY-MM-DD format
        limit: Maximum number of results
    """
    results = search.search_by_date_range(start, end, limit=limit)
    return json.dumps(results, indent=2, default=str)


@mcp.tool()
def get_embedding_status() -> str:
    """Check the status of document embeddings.

    Returns how many documents and chunks have been embedded so far.
    """
    stats = db.get_embedding_stats()
    return json.dumps(stats, indent=2)
