*** Settings ***
Documentation       This Robot Framework file provides a suite of reusable keywords for
...                 executing diverse operations such as validating configurations, uploading
...                 files, and generating coverage reports. It draws on resources defined in
...                 the 'resources.robot' file.

Resource            resources.robot


*** Keywords ***
Validate Configuration
    [Documentation]    Validate if configuration behaves as expected
    [Arguments]    ${file_name}    ${expected_status_code}    ${expected_response}=${EMPTY}
    ${result}=    Run Process
    ...    ${CADDY_VALIDATE} ${file_name}
    ...    shell=True
    ...    env:GOCOVERDIR=${OUTPUT DIR}/go-coverage
    Should Be Equal As Integers    ${result.rc}    ${expected_status_code}
    Should Contain    ${result.stderr}    ${expected_response}

Upload File
    [Documentation]    Test uploading a single file. The ${file_path} argument should
    ...    be the absolute path to the file.
    [Arguments]    ${file_path}    ${url}=${BASE_URL}/upload    ${expected_status}=201
    ...    ${text_expected}=True
    ${file_data}=    Get Binary File    ${file_path}
    ${file_name}=    Set Variable    /test.txt
    ${response}=    PUT
    ...    ${url}${file_name}
    ...    data=${file_data}
    ...    expected_status=${expected_status}
    Log    ${response}
    IF    ${text_expected} == True
        Should Match    ${response.text}    File ${file_name} created successfully.
    END

Readback File
    [Documentation]    Test reading back a single file. The ${file_path} argument should
    ...    be the absolute path to the file.
    [Arguments]    ${file_path}    ${url}=${BASE_URL}    ${expected_status}=200
    ${file_data}=    Get Binary File    ${file_path}
    ${file_name}=    Set Variable    /test.txt
    ${response}=    GET
    ...    ${url}${file_name}
    ...    expected_status=${expected_status}
    Log    ${response}

Convert Coverage Fragments
    [Documentation]    Convert coverage fragments (from a go run/build -cover execution) into
    ...    a single file
    [Arguments]    ${cov_path}
    ${result}=    Run Process
    ...    go tool covdata textfmt -i\=${OUTPUT DIR}/go-coverage -o\=${cov_path}
    ...    shell=True
    Should Be Equal As Integers    ${result.rc}    0

Expect Successful Execution
    [Documentation]    Runs a ${command} and expects it to succeed. ${command}
    ...    should be a string representing the shell command.
    [Arguments]    ${command}
    ${result}=    Run Process    ${command}    shell=True
    IF    ${result.rc} != 0    Log Many    ${result.stderr}    ${result.stdout}
    Should Be Equal As Integers    ${result.rc}    0
    RETURN    ${result}

Get Coverage Filename From Suite Source
    [Documentation]    Splits `${SUITE SOURCE}` into path and filename. Constructs a
    ...    path to the coverage file in `${OUTPUT DIR}`. Returns the coverage full file
    ...    path and the coverage filename separately.
    ${path}    ${suite_filename}=    Split Path    ${SUITE SOURCE}
    ${suite_name}    ${ext}=    Split Extension    ${suite_filename}
    ${cov_path}=    Join Path    ${OUTPUT DIR}    ${suite_name}.coverage
    RETURN    ${cov_path}    ${suite_name}.coverage

Generate Coverage Report
    [Documentation]    Generate coverage report from generated files
    ${cov_path}    ${cov_filename}=    Get Coverage Filename From Suite Source

    # Generate collated coverage report from generated files if there are any
    ${dir_exists}=    Run Keyword And Return Status
    ...    Directory Should Exist    ${OUTPUT DIR}/go-coverage
    IF    ${dir_exists}
        ${dir_contents}=    List Files In Directory    ${OUTPUT DIR}/go-coverage
    ELSE
        ${dir_contents}=    Set Variable    ${None}
    END
    IF    ${dir_contents}    Convert Coverage Fragments    ${cov_path}

    # Generate HTML report from collated coverage report
    Expect Successful Execution    go tool cover -html\=${cov_path} -o\=${cov_path}.html

    # Extract coverage percentage from generated coverage file
    ${result}=    Expect Successful Execution    go tool cover -func\=${cov_path}
    ${percent}=    Get Regexp Matches    ${result.stdout}    total:.*?([0-9.]+%)$    1

    # Update Suite Metadata with coverage information and links to generated files
    Set Suite Metadata
    ...    Code coverage
    ...    ${percent[0]} [${cov_filename}.html|HTML Report] | [${cov_filename}|Coverage file]

Suite Setup
    [Documentation]    Ensure there is a directory for coverage files
    Create Directory    ${OUTPUT DIR}/go-coverage

Suite Teardown
    [Documentation]    Generate coverage report and remove coverage directory
    Generate Coverage Report
    Remove Directory    ${OUTPUT DIR}/go-coverage    recursive=True

Wait Until Caddy Is Ready
    [Documentation]    Return only when Caddy is ready to accept connections
    Wait Until Keyword Succeeds    30s    0.5s    GET    ${BASE_URL}

Expect Caddy Not Ready
    [Documentation]    Check that Caddy is not ready to accept connections
    ${result}=    Run Keyword And Return Status    GET    ${BASE_URL}
    Should Be Equal
    ...    ${result}
    ...    ${False}
    ...    msg=Caddy seems to be running already, which is unexpected in this test context.

Suite Setup With Caddy
    [Documentation]    Run regular suite setup, start Caddy and wait until it is available
    Suite Setup
    Create Directory    ./test
    Expect Caddy Not Ready
    Start Process
    ...    ${CADDY_RUN} examples/Caddyfile.basic-auth
    ...    shell=True
    ...    env:GOCOVERDIR=${OUTPUT DIR}/go-coverage
    ...    alias=caddy
    Wait Until Caddy Is Ready

Suite Teardown With Caddy
    [Documentation]    Perform a graceful shutdown if Caddy and run the regular suite teardown
    Send Signal To Process    SIGINT    handle=caddy    group=True
    ${result}=    Wait For Process    timeout=10s    on_timeout=terminate
    Log    ${result.stderr}
    Suite Teardown
