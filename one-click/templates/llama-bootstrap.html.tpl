<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Opening Paperless Ag AI</title>
  </head>
  <body>
    <script>
      (function () {
        var mcpServers = [
          {
            id: "paperless-ag",
            enabled: true,
            url: "http://caddy:8088/mcp",
            name: "Paperless Ag",
            requestTimeoutSeconds: 300,
            useProxy: true,
          },
        ];
        var defaults = {
          systemMessage:
            "You are Paperless Ag's local AI chat. When the user asks about documents, use the Paperless Ag MCP tools instead of guessing. Prefer search_documents for broad questions and get_document for follow-up detail. Keep answers concise and cite document titles or IDs from tool results when available.",
          max_tokens: 512,
          temperature: 0.7,
          top_k: 20,
          top_p: 0.8,
          presence_penalty: 1.5,
          agenticMaxTurns: 6,
          showToolCallInProgress: true,
          alwaysShowAgenticTurns: true,
          mcpRequestTimeoutSeconds: 300,
          mcpServers: JSON.stringify(mcpServers),
        };
        var current = {};
        try {
          current = JSON.parse(localStorage.getItem("LlamaUi.config") || "{}");
        } catch (e) {
          current = {};
        }
        localStorage.setItem(
          "LlamaUi.config",
          JSON.stringify(
            Object.assign({}, defaults, current, {
              mcpServers: defaults.mcpServers,
            }),
          ),
        );
        localStorage.setItem(
          "LlamaUi.mcpDefaultEnabled",
          JSON.stringify([{ serverId: "paperless-ag", enabled: true }]),
        );
        localStorage.setItem(
          "LlamaUi.favoriteModels",
          JSON.stringify([
            "qwen3.5-2b-balanced",
            "qwen3-0.6b-fast",
            "qwen3.5-0.8b-small",
            "gemma3-1b-light",
            "functiongemma-270m-tools",
            "gemma4-e2b-agentic-large",
          ]),
        );
        localStorage.setItem("PaperlessAg.llamaBootstrap", "1");
        window.location.replace("/index.html");
      })();
    </script>
  </body>
</html>
