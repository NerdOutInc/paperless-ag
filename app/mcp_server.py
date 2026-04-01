from mcp.server.fastmcp import FastMCP
import search
import db
import config


def _create_mcp():
    if config.MCP_AUTH_TOKEN:
        try:
            from mcp.server.auth.provider import AccessToken, TokenVerifier

            class StaticTokenVerifier(TokenVerifier):
                async def verify_token(self, token):
                    if token == config.MCP_AUTH_TOKEN:
                        return AccessToken(
                            token=token,
                            client_id="paperless-ag",
                            scopes=[],
                        )
                    return None

            server = FastMCP(
                "Paperless Ag",
                json_response=True,
                token_verifier=StaticTokenVerifier(),
            )
            print("MCP authentication enabled.")
            return server
        except Exception:
            print("WARNING: MCP auth not supported in this SDK version.")
            print("Running without authentication.")

    return FastMCP("Paperless Ag", json_response=True)


mcp = _create_mcp()


@mcp.tool()
def search_documents(query: str, limit: int = 10) -> list:
    """Search farm documents using hybrid semantic and keyword search.

    Combines vector similarity search (finds conceptually related documents)
    with keyword search (finds exact term matches). Use this for queries like
    "find everything related to nitrogen management" or "crop insurance documents".

    Args:
        query: Natural language search query
        limit: Maximum number of results (default 10)
    """
    return search.hybrid_search(query, limit=limit)


@mcp.tool()
def get_document(document_id: int) -> dict:
    """Get full details and content for a specific document.

    Use this after searching to read the complete text of a document.

    Args:
        document_id: The Paperless document ID
    """
    return search.get_document(document_id)


@mcp.tool()
def list_tags() -> list:
    """List all tags in the document management system.

    Returns all available tags. Useful for understanding how documents
    are organized and for filtering searches.
    """
    return search.list_tags()


@mcp.tool()
def list_document_types() -> list:
    """List all document types in the system.

    Returns categories like Soil Test Report, Crop Insurance Policy, etc.
    """
    return search.list_document_types()


@mcp.tool()
def search_by_tag(tag: str, limit: int = 20) -> list:
    """Find all documents with a specific tag.

    Args:
        tag: Tag name (e.g., horob-family-farms, corn, nitrogen)
        limit: Maximum number of results
    """
    return search.search_by_tag(tag, limit=limit)


@mcp.tool()
def search_by_date_range(start: str, end: str, limit: int = 20) -> list:
    """Find documents within a date range.

    Args:
        start: Start date in YYYY-MM-DD format
        end: End date in YYYY-MM-DD format
        limit: Maximum number of results
    """
    return search.search_by_date_range(start, end, limit=limit)


@mcp.tool()
def get_embedding_status() -> dict:
    """Check the status of document embeddings.

    Returns how many documents and chunks have been embedded so far.
    """
    return db.get_embedding_stats()
