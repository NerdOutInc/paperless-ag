import time
import auth
import config
import db
import embeddings


class EmbeddingWorker:
    def __init__(self):
        self.api_url = config.PAPERLESS_API_URL

    def get_all_document_ids(self):
        doc_ids = []
        url = f"{self.api_url}/api/documents/?page_size=100&fields=id"
        while url:
            resp = auth.api_request("GET", url)
            data = resp.json()
            for doc in data.get("results", []):
                doc_ids.append(doc["id"])
            url = data.get("next")
        return doc_ids

    def get_document_content(self, doc_id):
        resp = auth.api_request(
            "GET", f"{self.api_url}/api/documents/{doc_id}/",
        )
        return resp.json().get("content", "")

    def embed_document(self, doc_id):
        content = self.get_document_content(doc_id)
        if not content or not content.strip():
            print(f"  Skipping doc {doc_id}: no content")
            return

        chunks = embeddings.chunk_text(content)
        chunk_embeddings = embeddings.get_embeddings(chunks)

        records = [
            (i, text, emb)
            for i, (text, emb) in enumerate(zip(chunks, chunk_embeddings))
        ]

        db.store_embeddings(doc_id, records)
        print(f"  Embedded doc {doc_id}: {len(chunks)} chunks")

    def sync(self):
        try:
            all_ids = self.get_all_document_ids()
            embedded_ids = db.get_embedded_doc_ids()
            new_ids = [i for i in all_ids if i not in embedded_ids]

            if not new_ids:
                return

            print(f"Embedding {len(new_ids)} new documents...")
            for doc_id in new_ids:
                try:
                    self.embed_document(doc_id)
                except Exception as e:
                    print(f"  Error embedding doc {doc_id}: {e}")

            stats = db.get_embedding_stats()
            print(f"Sync complete: {stats['total_docs']} docs, {stats['total_chunks']} chunks")

        except Exception as e:
            print(f"Sync error: {e}")

    def run(self):
        print("Embedding worker starting...")

        # Wait for Paperless to be ready
        for attempt in range(30):
            try:
                auth.get_token()
                print("Connected to Paperless API.")
                break
            except Exception:
                print(f"Waiting for Paperless... (attempt {attempt + 1})")
                time.sleep(10)
        else:
            print("ERROR: Could not connect to Paperless after 30 attempts")
            return

        # Load embedding model
        embeddings.load_model()

        # Initial sync
        self.sync()

        # Ongoing sync loop
        while True:
            time.sleep(config.SYNC_INTERVAL)
            self.sync()
