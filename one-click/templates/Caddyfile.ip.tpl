:80 {
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
    }

    @discovery path /.well-known/oauth-authorization-server /.well-known/openid-configuration
    handle @discovery {
        respond 404
    }

    @mcp path /mcp /mcp/*
    handle @mcp {
        reverse_proxy companion:3001 {
            header_up Host localhost:3001
        }
    }

    handle {
        reverse_proxy paperless:8000
    }
}

http://{{AI_DOMAIN}} {
    @bootstrap {
        path /
        not header Cookie *paperless_ag_llama_bootstrapped=1*
    }
    handle @bootstrap {
        root * /srv/llama-bootstrap
        rewrite * /llama-bootstrap.html
        file_server
    }
    handle {
        reverse_proxy llama:8080
    }
}

:8088 {
    @mcp path /mcp /mcp/*
    handle @mcp {
        reverse_proxy companion:3001 {
            header_up Host localhost:3001
            header_up Authorization "Bearer {env.MCP_AUTH_TOKEN}"
        }
    }
    handle {
        respond 404
    }
}
