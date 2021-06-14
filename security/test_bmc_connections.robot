*** Settings ***
Documentation  Connections and authentication module stability tests.

Resource  ../lib/bmc_redfish_resource.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/openbmc_ffdc.robot
Resource  ../lib/resource.robot
Resource  ../lib/utils.robot
Resource  ../lib/connection_client.robot
Library   ../lib/bmc_network_utils.py

Library   SSHLibrary
Library   Collections
Library   XvfbRobot
Library   OperatingSystem
Library   Selenium2Library  120  120
Library   Telnet  30 Seconds
Library   Screenshot

Variables  ../gui/data/gui_variables.py

*** Variables ***

${iterations}         10000
${loop_iteration}     ${1000}
${hostname}           test_hostname
${MAX_UNAUTH_PER_IP}  ${5}
${bmc_url}            https://${OPENBMC_HOST}


*** Test Cases ***

Test Patch Without Auth Token Fails
    [Documentation]  Send patch method without auth token and verify it throws an error.
    [Tags]   Test_Patch_Without_Auth_Token_Fails

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Flood Patch Without Auth Token And Check Stability Of BMC
    [Documentation]  Flood patch method without auth token and check BMC stability.
    [Tags]  Flood_Patch_Without_Auth_Token_And_Check_Stability_Of_BMC
    @{status_list}=  Create List

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th iteration
        Run Keyword And Ignore Error
        ...  Redfish.Patch  ${REDFISH_NW_ETH_IFACE}${ethernet_interface}  body={'HostName': '${hostname}'}

        # Every 100th iteration, check BMC allows patch with auth token.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Login And Configure Hostname
        Run Keyword If  ${status} == False  Append To List  ${status_list}  ${status}
    END
    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${status_list}

    Should Be Equal  ${fail_count}  0
    ...  msg=Patch operation failed ${fail_count} times in ${verify_count} attempts


Verify Uer Cannot Login After 5 Non-Logged In Sessions
    [Documentation]  User should not be able to login when there
    ...  are 5 non-logged in sessions.
    [Tags]  Verify_User_Cannot_Login_After_5_Non-Logged_In_Sessions

    FOR  ${i}  IN RANGE  ${0}  ${MAX_UNAUTH_PER_IP}
       SSHLibrary.Open Connection  ${OPENBMC_HOST}
       Start Process  ssh ${OPENBMC_USERNAME}@${OPENBMC_HOST}  shell=True
    END

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    Should Be Equal  ${status}  ${False}


Test Post Without Auth Token Fails
    [Documentation]  Send post method without auth token and verify it throws an error.
    [Tags]   Test_Post_Without_Auth_Token_Fails

    ${user_info}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{user_info}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Flood Post Without Auth Token And Check Stability Of BMC
    [Documentation]  Flood post method without auth token and check BMC stability.
    [Tags]  Flood_Post_Without_Auth_Token_And_Check_Stability_Of_BMC

    @{status_list}=  Create List
    ${user_info}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}

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

    Should Be Equal  ${fail_count}  0
    ...  msg=Post operation failed ${fail_count} times in ${verify_count} attempts


Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]  Check BMC stability with large number of SSH wrong login requests.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability
    [Setup]  Set Account Lockout Threshold
    [Teardown]  FFDC On Test Case Fail

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    @{ssh_status_list}=  Create List
    FOR  ${i}  IN RANGE  ${loop_iteration}
      Log To Console  ${i}th iteration
      ${invalid_password}=   Catenate  ${OPENBMC_PASSWORD}${i}
      Run Keyword and Ignore Error
      ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${invalid_password}

      # Every 100th iteration Login with correct credentials
      ${status}=   Run keyword If  ${i} % ${100} == ${0}  Run Keyword And Return Status
      ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
      Run Keyword If  ${status} == ${False}  Append To List  ${ssh_status_list}  ${status}
      SSHLibrary.Close Connection
    END

    ${valid_login_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${ssh_status_list}
    Should Be Equal  ${fail_count}  ${0}
    ...  msg= Login Failed ${fail_count} times in ${valid_login_count} attempts.


Test Stability On Large Number Of Wrong Login Attempts To GUI
    [Documentation]  Test stability on large number of wrong login attempts to GUI.
    [Tags]   Test_Stability_On_Large_Number_Of_Wrong_Login_Attempts_To_GUI

    @{status_list}=  Create List

    # Open headless browser.
    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=browser1
    Set Window Size  1920  1080

    Go To  ${bmc_url}

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th login
        Run Keyword And Ignore Error  Login to GUI With Wrong Credentials

        # Every 100th iteration, check BMC GUI is responsive.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Open Browser  ${bmc_url}
        Append To List  ${status_list}  ${status}
        Run Keyword If  '${status}' == 'True'  Run Keywords  Close Browser  AND  Switch Browser  browser1
    END

    ${fail_count}=  Count Values In List  ${status_list}  False
    Run Keyword If  ${fail_count} > ${0}  FAIL  Could not open BMC GUI ${fail_count} times


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

    ${user_info}=  Create Dictionary
    ...  UserName=test_user  Password=TestPwd123  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{user_info}
    ...  valid_status_codes=[${HTTP_OK}]


Set Account Lockout Threshold
   [Documentation]  Set user account lockout threshold.

   [Teardown]  Redfish.Logout

   Redfish.Login
   Redfish.Patch  /redfish/v1/AccountService  body=[('AccountLockoutThreshold', 0)]


Login to GUI With Incorrect Credentials
    [Documentation]  Login to GUI With Wrong Credentials.

    Input Text  ${xpath_textbox_username}  root
    Input Password  ${xpath_textbox_password}  incorrect_password
    Click Button  ${xpath_login_button}
