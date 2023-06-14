*** Settings ***
Documentation       Verifies the build process of distribution binaries and
...                 ensures that the built binaries execute successfully.

Resource            resources/keywords.robot


*** Test Cases ***
Build distribution binaries
    [Documentation]    Builds the distribution binaries using the
    ...    'make dist-all' command.
    Expect Successful Execution
    ...    make dist-all

Built binaries should run
    [Documentation]    Verifies that all the built binaries in the 'dist/'
    ...    subdirectory execute successfully.
    ${binary_list}=    List Files In Directory    ./dist/
    FOR    ${binary}    IN    @{binary_list}
        Expect Successful Execution    ./dist/${binary} list-modules
    END
