# caddy-put-upload

ChatGPT: Summarize what this project does.

## Using

### Pre built binaries

ChatGPT: If you want to use it with basic authentnication, or with the security module, you can use the pre built binaries.

the dist/caddy-put-linux-x86_64 has the caddy standard modules.
the dist/caddy-put-security-linux-x86_64 has the caddy standard modules and the security module.

### Build your own

Example of building your own docker image:

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

ChatGPT: Describe here

#### Not using VSCode, but docker

```shell
$ docker build -t madworx/caddy-put-upload -f .devcontainer/Dockerfile .
$ docker run -it --rm -v $(pwd):/w -w /w madworx/caddy-put-upload make install-deps all
```

### Fully local installation

You'll need the following prerequisites installed and in your `$PATH`:

- go 1.20+
- robot framework 6.0+
- python 3.9+
- make
- git

As well as:

- python packages: listed in `e2e_tests/resources/requirements.txt`.
- golang: `xcaddy`, `staticcheck` and `gofumpt`.

For Debian-based installations:

```shell
$ sudo apt-get install -y \
    build-essential git \
    python3 python3-pip golang

$ pip3 install -r e2e_tests/resources/requirements.txt
$ go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
$ go install honnef.co/go/tools/cmd/staticcheck@latest
```
