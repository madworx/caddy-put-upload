package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// plug in the HTTP server type
	_ "github.com/caddyserver/caddy/v2/modules/standard"
	_ "github.com/madworx/caddy-put-upload"
)

func main() {
	caddycmd.Main()
}
