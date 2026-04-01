from sentence_transformers import SentenceTransformer
import config

_model = None


def load_model():
    global _model
    print(f"Loading embedding model: {config.EMBEDDING_MODEL}")
    _model = SentenceTransformer(config.EMBEDDING_MODEL)
    print("Model loaded.")
    return _model


def get_model():
    if _model is None:
        return load_model()
    return _model


def get_embedding(text):
    model = get_model()
    return model.encode(text).tolist()


def get_embeddings(texts):
    model = get_model()
    return model.encode(texts).tolist()


def chunk_text(text, chunk_size=None, chunk_overlap=None):
    if chunk_size is None:
        chunk_size = config.CHUNK_SIZE
    if chunk_overlap is None:
        chunk_overlap = config.CHUNK_OVERLAP

    if chunk_overlap >= chunk_size:
        raise ValueError(f"chunk_overlap ({chunk_overlap}) must be less than chunk_size ({chunk_size})")

    words = text.split()
    if not words:
        return []

    if len(words) <= chunk_size:
        return [text]

    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        if end >= len(words):
            break
        start += chunk_size - chunk_overlap

    return chunks
