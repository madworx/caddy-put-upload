*** Settings ***
Documentation       Executes test cases for handling file uploads
...                 and processing non-PUT operations.

Resource            resources/keywords.robot

Suite Setup         Suite Setup With Caddy
Suite Teardown      Suite Teardown With Caddy


*** Test Cases ***
Test simple upload
    [Documentation]    Simple uploads of a file should work
    Upload File    go.mod

Read back uploaded file
    [Documentation]    Readback of uploaded files should work
    Readback File    go.mod

Unauthenticated upload should fail
    [Documentation]    Unauthenticated uploads should fail
    Upload File    go.mod    ${BASE_URL_NOAUTH}/upload    expected_status=401    text_expected=False

Non PUT should be ignored by module
    [Documentation]    Non-PUT operations should be ignored by the module
    ...    (this is to improve coverage)
    GET    ${BASE_URL}/upload/test.txt    expected_status=404
