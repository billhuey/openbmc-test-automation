*** Settings ***
Documentation  Connections and authentication module stability tests.

Resource  ../lib/bmc_redfish_resource.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/openbmc_ffdc.robot
Library   ../lib/bmc_network_utils.py

Library   OperatingSystem
Library   Collections

*** Variables ***

${iterations}  10000
${hostname}    test_hostname

*** Test Cases ***

Test Patch Without Auth Token Fails
    [Documentation]  Send patch method without auth token and verify it throws an error.
    [Tags]   Test Patch Without Auth Token Fails

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Flood Patch Without Auth Token And Check Stability Of BMC
    [Documentation]  Flood patch method without auth token and check BMC stability.
    [Tags]  Flood_Patch_Without_Auth_Token_And_Check_Stability_Of_BMC
    @{status_list}=  Create List

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th iteration
        Run Keyword And Ignore Error
        ...  Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}

        # Every 100th iteration, check BMC allows patch with auth token.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Login And Configure Hostname
        Run Keyword If  ${status} == False  Append To List  ${status_list}  ${status}
    END
    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${status_list}

    Should Be Equal  ${fail_count}  0  msg=Patch operation failed ${fail_count} times in ${verify_count} attempts


Test Post Without Auth Token Fails
    [Documentation]  Send post method without auth token and verify it throws an error.
    [Tags]   Test_Post_Without_Auth_Token_Fails  tagg

    ${user_info}=  Create Dictionary  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{user_info}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Flood Post Without Auth Token And Check Stability Of BMC
    [Documentation]  Flood post method without auth token and check BMC stability.
    [Tags]  Flood_Post_Without_Auth_Token_And_Check_Stability_Of_BMC  tagg

    @{status_list}=  Create List

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th iteration
        Run Keyword And Ignore Error
        ...  Redfish.Post   /redfish/v1/AccountService/Accounts/  body=&{user_info}

        # Every 100th iteration, check BMC allows post with auth token.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Login And Create User
        Run Keyword If  ${status} == False  Append To List  ${status_list}  ${status}
    END
    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${status_list}

    Should Be Equal  ${fail_count}  0  msg=Post operation failed ${fail_count} times in ${verify_count} attempts


*** Keywords ***

Login And Configure Hostname
    [Documentation]  Login and configure hostname

    [Teardown]  Redfish.Logout

    Redfish.Login

    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Login And Create User
    [Documentation]  Login and create user

    [Teardown]  Redfish.Logout

    Redfish.Login

    ${user_info}=  Create Dictionary  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{user_info}  valid_status_codes=[${HTTP_OK}]
