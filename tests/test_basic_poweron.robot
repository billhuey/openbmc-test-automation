*** Settings ***
Documentation  Test power on for HW CI.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Test Setup          Start SOL Console Logging
Test Teardown       Test Exit Logs

Force Tags  chassisboot

*** Variables ***

# User may pass LOOP_COUNT.
# By default 2 cycle for CI/CT.
${LOOP_COUNT}  ${2}

# Error strings to check from journald.
${ERROR_REGEX}   SEGV|core-dump

*** Test Cases ***

Power On Test
    [Documentation]  Power off and on.
    [Tags]  Power_On_Test

    Repeat Keyword  ${LOOP_COUNT} times  Host Off And On


Check For Application Failures
    [Documentation]  Parse the journal log and check for failures.
    [Tags]  Check_For_Application_Failures

    Open Connection And Log In

    ${journal_log}=  Execute Command On BMC
    ...  journalctl --no-pager | egrep '${ERROR_REGEX}'

    Should Be Empty  ${journal_log}

*** Keywords ***

Test Exit Logs
    [Documentation]  Collect FFDC and SOL log.
    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}

Host Off And On
    [Documentation]  Verify power off and on.

    Initiate Host PowerOff
    Wait Until Keyword Succeeds  5 min  10 sec  Is OS Off

    Initiate Host Boot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Starting
    Verify PNOR Update

    Flush REST Sessions

