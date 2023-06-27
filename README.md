# caddy-put-upload

caddy-put-upload is a project that allows you to use HTTP PUT requests for file uploads in the Caddy server.

## Using

### Pre built binaries

For use with basic authentication or the security module, you can utilize the pre-built binaries available.

- `dist/caddy-put-linux-x86_64` has the caddy standard modules.
- `dist/caddy-put-security-linux-x86_64` has the caddy standard modules and the security module.

### Build your own

You can build your own Docker image using the example provided:

```dockerfile
FROM caddy:2.6.4-builder AS builder

RUN xcaddy build \
        --with github.com/greenpau/caddy-security@v1.1.19 \
        --with github.com/madworx/caddy-put-upload

FROM caddy:2.6.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

### Contributing

#### Easy mode: Use VSCode dev container

You can contribute to this project using the VSCode dev container which provides a pre-configured development environment.

#### Not using VSCode, but docker

If you're not using VSCode but have Docker installed, you can still contribute by building and running the project using Docker.

```shell
$ docker build -t madworx/caddy-put-upload -f .devcontainer/Dockerfile .
$ docker run -it --rm -v $(pwd):/w -w /w madworx/caddy-put-upload make install-deps all
```

### Fully local installation

For a fully local installation, ensure the following prerequisites are installed and in your `$PATH`:

- go 1.20+
- robot framework 6.0+
- python 3.9+
- make
- git

Additional requirements include:

- Python packages: As listed in e2e_tests/resources/requirements.txt.
- Golang packages: xcaddy, staticcheck and gofumpt.

For Debian-based installations:

```shell
$ sudo apt-get install -y \
    build-essential git \
    python3 python3-pip golang

$ pip3 install -r e2e_tests/resources/requirements.txt
$ go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
$ go install honnef.co/go/tools/cmd/staticcheck@latest
```
