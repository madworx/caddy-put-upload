*** Settings ***
Documentation       A series of test cases designed to verify the behavior of various
...                 configurations, ranging from valid to invalid scenarios.
...                 It utilizes keywords and resources defined in the
...                 'resources/keywords.robot' file for test execution.

Resource            resources/keywords.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Test Cases ***
Example configuration: basic authentication
    [Documentation]    Test that example configuration with HTTP basic authentication is accepted
    Validate Configuration    examples/Caddyfile.basic-auth    0

Example configuration: no authentication
    [Documentation]    Test that example configuration without authentication is accepted
    Validate Configuration    examples/Caddyfile.no-authentication    0

Invalid configuration: empty
    [Documentation]    Test that an invalid configuration is rejected (no arguments)
    Validate Configuration    e2e_tests/resources/Caddyfile.invalid-no-arg
    ...    1
    ...    Wrong argument count or unexpected line ending after 'http_put_file'

Invalid configuration: structure
    [Documentation]    Test that an invalid configuration is rejected (nested argument)
    Validate Configuration    e2e_tests/resources/Caddyfile.invalid-nested-args
    ...    1
    ...    Wrong argument count or unexpected line ending after 'http_put_file'
