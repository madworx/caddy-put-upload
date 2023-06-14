*** Settings ***
Documentation       Aggregate multiple code coverage reports into a single report.
...                 It leverages the gocovmerge utility, a Go tool that merges multiple
...                 coverage profiles. The suite utilizes keywords defined in the
...                 resources/keywords.robot file.

Resource            resources/keywords.robot


*** Test Cases ***
Collate code coverage reports
    [Documentation]    Combine all code coverage profiles into one.
    ${cov_path}    ${cov_filename}=    Get Coverage Filename From Suite Source
    Expect Successful Execution
    ...    go run cmd/gocovmerge/gocovmerge.go ${OUTPUT DIR}/*.coverage > ${cov_path}
    Generate Coverage Report
