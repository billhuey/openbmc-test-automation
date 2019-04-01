*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish account service is available.
    [Tags]  Verify_AccountService_Available

    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/AccountService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}

Redfish Create and Verify Users
    [Documentation]  Create Redfish users with various roles
    [Tags]  Redfish_Create_and_Verify_Users
    [Template]  Redfish Create And Verify User

     # username       password    role_id         enabled
       admin_user     TestPwd123  Administrator   ${True}
       operator_user  TestPwd123  Operator        ${True}
       user_user      TestPwd123  User            ${True}
       callback_user  TestPwd123  Callback        ${True}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password
    [Tags]  Verify_Redfish_User_with_Wrong_Password
    [Template]  Verify Redfish User with Wrong Password

     # username       password    role_id         enabled  wrong_password
       admin_user     TestPwd123  Administrator   ${True}  alskjhfwurh
       operator_user  TestPwd123  Operator        ${True}  12j8a8uakjhdaosiruf024
       user_user      TestPwd123  User            ${True}  12
       callback_user  TestPwd123  Callback        ${True}  !#@D#RF#@!D

Verify Create User Without Enabling It
    [Documentation]  Verify Create User Without Enabling It
    [Tags]  Verify_Create_User_Without_Enabling_It

    # Delete if the user exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=admin_user  Password=TestPwd123  RoleId=Administrator  Enabled=${False}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    ${data}=  Create Dictionary  UserName=admin_user  Password=TestPwd123
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${data}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user

Verify Redfish User Persistence After Reboot
    [Documentation]  Verify Redfish user persistence after reboot
    [Tags]  Verify_Redfish_User_Persistence_After_Reboot
    [Template]  Verify Redfish User After Reboot

     # username       password    role_id         enabled
       admin_user     TestPwd123  Administrator   ${True}
       operator_user  TestPwd123  Operator        ${True}
       user_user      TestPwd123  User            ${True}
       callback_user  TestPwd123  Callback        ${True}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout

Redfish Create And Verify User
    [Documentation]  Redfish create and verify user.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created.
    # enabled             The decision if it should be enabled.

    # Example:
    #{
    #"@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount",
    #"@odata.id": "/redfish/v1/AccountService/Accounts/test1",
    #"@odata.type": "#ManagerAccount.v1_0_3.ManagerAccount",
    #"Description": "User Account",
    #"Enabled": true,
    #"Id": "test1",
    #"Links": {
    #  "Role": {
    #    "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
    #  }
    #},

    # Delete if the user exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    Redfish.Login  ${username}  ${password}

    # Validate Role Id of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${userName}  RoleId
    Should Be Equal  ${role_id}  ${role_config}

    Redfish.Get  /redfish/v1/AccountService/Accounts/${userName}

    # Delete Specified User
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

Verify Redfish User with Wrong Password
    [Documentation]  Verify Redfish User with Wrong Password
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${wrong_password}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created.
    # enabled             The decision if it should be enabled.
    # wrong_password      Any invalid password.

    # Delete if the user exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    Redfish.Login  ${username}  ${password}

    Redfish.Logout

    # Attempt to login with created user with invalid password.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${wrong_password}

    Redfish.Login

    # Delete newly created user.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

Verify Redfish User After Reboot
    [Documentation]  Verify Redfish User After Reboot
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role id of the user to be created.
    # enabled             The decision if it should be enabled.

    # Delete if the user exist.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${userName}

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Logout

    # Login with created user.
    Redfish.Login  ${username}  ${password}

    # Reboot
    Redfish Host Reboot

    # Login again with created user.
    Redfish.Login  ${username}  ${password}

