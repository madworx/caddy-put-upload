*** Settings ***
Documentation       This test suite performs code linting for different languages.

Resource            resources/keywords.robot


*** Test Cases ***
Golang
    [Documentation]    Lint Golang code
    Expect Successful Execution    make lint-go

Robot Framework
    [Documentation]    Lint Robot Framework code
    Expect Successful Execution    make lint-robot

Python
    [Documentation]    Lint Python code
    Expect Successful Execution    make lint-python
