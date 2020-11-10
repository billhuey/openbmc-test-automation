*** Settings ***
Documentation   This suite is for disable field mode if enabled.

Resource        ../lib/code_update_utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/dump_utils.robot

Test Teardown   FFDC On Test Case Fail

*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE|Failed to start

*** Test Cases ***

Verify Field Mode Is Disable
    [Documentation]  Disable software manager field mode.
    [Tags]  Verify_Field_Mode_Is_Disable

    # Field mode is enabled before running CT.
    # It is to ensure that the setting is not changed during CT
    Field Mode Should Be Enabled
    Disable Field Mode And Verify Unmount


Verify No BMC Dump And Application Failures
    [Documentation]  Verify no BMC dump exist.
    [Tags]  Verify_No_BMC_Dump_And_Application_Failures

    ${resp}=  OpenBMC Get Request  ${DUMP_URI}
    Run Keyword If  '${resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  Set Test Variable  ${DUMP_ENTRY_URI}  /xyz/openbmc_project/dump/entry/

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=BMC dump(s) were not deleted as expected.

    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b
