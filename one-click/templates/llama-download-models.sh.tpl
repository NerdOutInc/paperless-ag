#!/bin/sh
set -eu

MODEL_DIR="/models"
mkdir -p "$MODEL_DIR"

download_model() {
    filename="$1"
    url="$2"
    target="$MODEL_DIR/$filename"
    tmp="$target.tmp"

    if [ -s "$target" ]; then
        echo "[OK] $filename already exists"
        return 0
    fi

    echo "[..] Downloading $filename"
    rm -f "$tmp"
    python3 - "$url" "$tmp" <<'PY'
import sys
import time
import urllib.request

url, target = sys.argv[1], sys.argv[2]
request = urllib.request.Request(url, headers={"User-Agent": "paperless-ag-llama-model-installer"})

for attempt in range(1, 4):
    try:
        with urllib.request.urlopen(request, timeout=60) as response, open(target, "wb") as output:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                output.write(chunk)
        break
    except Exception:
        if attempt == 3:
            raise
        time.sleep(5 * attempt)
PY
    mv "$tmp" "$target"
    echo "[OK] Downloaded $filename"
}

download_model "Qwen3-0.6B-Q8_0.gguf" "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf"
download_model "Qwen_Qwen3.5-0.8B-Q4_K_M.gguf" "https://huggingface.co/bartowski/Qwen_Qwen3.5-0.8B-GGUF/resolve/main/Qwen_Qwen3.5-0.8B-Q4_K_M.gguf"
download_model "Qwen_Qwen3.5-2B-Q4_K_M.gguf" "https://huggingface.co/bartowski/Qwen_Qwen3.5-2B-GGUF/resolve/main/Qwen_Qwen3.5-2B-Q4_K_M.gguf"
download_model "gemma-3-1b-it-Q4_K_M.gguf" "https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf"
download_model "functiongemma-270m-it-q8_0.gguf" "https://huggingface.co/ggml-org/functiongemma-270m-it-GGUF/resolve/main/functiongemma-270m-it-q8_0.gguf"
download_model "google_gemma-4-E2B-it-Q4_K_M.gguf" "https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q4_K_M.gguf"

cat > "$MODEL_DIR/models.ini" <<'INI'
version = 1

[*]
ctx-size = 8192
n-predict = 512
parallel = 1
jinja = true

[qwen3.5-2b-balanced]
model = /models/Qwen_Qwen3.5-2B-Q4_K_M.gguf
chat-template-kwargs = {"enable_thinking":false}
reasoning = off

[qwen3-0.6b-fast]
model = /models/Qwen3-0.6B-Q8_0.gguf
chat-template-kwargs = {"enable_thinking":false}
reasoning = off

[qwen3.5-0.8b-small]
model = /models/Qwen_Qwen3.5-0.8B-Q4_K_M.gguf
chat-template-kwargs = {"enable_thinking":false}
reasoning = off

[gemma3-1b-light]
model = /models/gemma-3-1b-it-Q4_K_M.gguf

[functiongemma-270m-tools]
model = /models/functiongemma-270m-it-q8_0.gguf

[gemma4-e2b-agentic-large]
model = /models/google_gemma-4-E2B-it-Q4_K_M.gguf
INI

cat > "$MODEL_DIR/ui-config.json" <<'JSON'
{
  "systemMessage": "You are Paperless Ag's local AI chat. When the user asks about documents, use the Paperless Ag MCP tools instead of guessing. Prefer search_documents for broad questions and get_document for follow-up detail. Keep answers concise and cite document titles or IDs from tool results when available.",
  "max_tokens": 512,
  "temperature": 0.7,
  "top_k": 20,
  "top_p": 0.8,
  "presence_penalty": 1.5,
  "agenticMaxTurns": 6,
  "showToolCallInProgress": true,
  "alwaysShowAgenticTurns": true,
  "mcpRequestTimeoutSeconds": 300,
  "mcpServers": "[{\"id\":\"paperless-ag\",\"enabled\":true,\"url\":\"http://caddy:8088/mcp\",\"name\":\"Paperless Ag\",\"requestTimeoutSeconds\":300,\"useProxy\":true}]"
}
JSON

echo "[OK] llama.cpp model presets ready"
