:80 {
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
