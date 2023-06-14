*** Settings ***
Documentation       This Robot Framework resource file specifies the essential
...                 libraries and predefined variables necessary for executing
...                 the associated test scripts.

Library             OperatingSystem
Library             Process
Library             String
Library             RequestsLibrary


*** Variables ***
${BASE_URL}             http://Bob:hiccup@localhost:8080/
${BASE_URL_NOAUTH}      http://localhost:8080/
${FILE_PATH}            go.mod
${CADDY_VALIDATE}       go run -cover cmd/caddy/main.go validate --config
${CADDY_RUN}            go run -cover cmd/caddy/main.go run --config
${CADDY_STOP}           go run -cover cmd/caddy/main.go stop --config
