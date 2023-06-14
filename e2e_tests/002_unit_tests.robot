*** Settings ***
Documentation       Run native unit tests for the golang code and serves to aggregate
...                 all test results into one report, also generating a coverage report.

Resource            resources/keywords.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Test Cases ***
Unit tests
    [Documentation]    Execute golang unit tests
    ${cov_path}    ${cov_filename}=    Get Coverage Filename From Suite Source
    ${result}=    Run Process
    ...    go test ./... -v -coverprofile\=${cov_path} -covermode\=set
    ...    shell=True
    Log Many    ${result.stdout}    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

Failing unit tests should be detected
    [Documentation]    Ensure that we notice if unit tests start to fail
    Copy File    e2e_tests/resources/test_fail.go    fail_test.go
    ${result}=    Run Process    go test ./... -v    shell=True
    Log Many    ${result.stdout}    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    1
    [Teardown]    Remove File    fail_test.go
