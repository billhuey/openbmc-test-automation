*** Settings ***
Documentation   This suite is to run some test at the end of execution.

Resource        ../lib/resource.robot
Resource        ../lib/bmc_redfish_resource.robot
Resource        ../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE|Failed to start


*** Test Cases ***

Verify No BMC Dump And Application Failures In BMC
    [Documentation]  Verify no BMC dump and application failure exists in BMC.
    [Tags]  Verify_No_BMC_Dump_And_Application_Failures_In_BMC

    # Check dump entry based on Redfish API availability.
    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    Log To Console  ${resp}

    Run Keyword If  '${resp.status}' == '${HTTP_OK}'
    ...  Should Be Equal As Strings  ${resp.dict["Members@odata.count"]}  0
    ...  msg=${resp.dict["Members@odata.count"]} dumps exist.

    ${rest_resp}=  Run Keyword If  '${resp.status}' == '${HTTP_NOT_FOUND}'
    ...  Check for REST Dumps

    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b


*** Keywords ***

Check for REST Dumps
    [Documentation]  Verify no BMC dump via REST path.

    ${rest_resp}=  Redfish.Get  /xyz/openbmc_project/dump/bmc/entry/list
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    Log To Console  ${rest_resp}

    Should Be Equal As Strings  ${rest_resp.status}  ${HTTP_NOT_FOUND}
    ...  msg=1 or more dumps exist.
