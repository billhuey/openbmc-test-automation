*** Settings ***

Documentation     Test client identifier feature on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Library           ../../lib/bmc_network_utils.py
Library           ../../lib/gen_robot_valid.py

Suite Setup       Redfish.Login
Suite Teardown    Delete All Redfish Sessions
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail


*** Test Cases ***

Create A Session With ClientID And Verify
   [Documentation]  Create a session with client id and verify client id is same.
   [Tags]  Create_A_Session_With_ClientID_And_Verify
   [Template]  Create And Verify Session ClientID

   # client_id           # reboot_flag
   12345                 False
   123456                False
   EXTERNAL-CLIENT-01    False
   EXTERNAL-CLIENT-02    False


Check ClientID Persistency On BMC Reboot
   [Documentation]  Create a session with client id and verify client id is same after the reboot.
   [Tags]  Check_ClientID_Persistency_On_BMC_Reboot
   [Template]  Create And Verify Session ClientID

   # client_id           # reboot_flag
   12345                 True
   EXTERNAL-CLIENT-01    True

*** Keywords ***

Create A Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}

    [Return]  ${resp}

Verify A Session Created With ClientID
    [Documentation]  Verify session created with client id.
    [Arguments]  ${client_id}  ${session_id}

    # Description of argument(s):
    # client_id    External client name.
    # session_id   This value is a session id.

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}

    # {
    #   "@odata.id": "/redfish/v1/SessionService/Sessions/H8q2ZKucSJ",
    #   "@odata.type": "#Session.v1_0_2.Session",
    #   "Description": "Manager User Session",
    #   "Id": "H8q2ZKucSJ",
    #   "Name": "User Session",
    #   "Oem": {
    #   "OpenBMC": {
    #  "@odata.type": "#OemSession.v1_0_0.Session",
    #  "ClientID": "",
    #  "ClientOriginIP": "::ffff:x.x.x.x"
    #       }
    #     },
    #   "UserName": "root"
    # }

    Rprint Vars  sessions
    @{words} =  Split String  ${sessions["Oem"]["OpenBMC"]["ClientOriginIP"]}  :
    ${ipaddr}=  Get Running System IP
    Set Test Variable  ${temp_ipaddr}  ${words}[-1]
    Valid Value  client_id  ['${sessions["Oem"]["OpenBMC"]["ClientID"]}']
    Valid Value  sessions["Id"]  ['${session_id}']
    Valid Value  temp_ipaddr  ${ipaddr}


Create And Verify Session ClientID
    [Documentation]  Create redifish session with client id and verify it remain same.
    [Arguments]  ${client_id}  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${session_info}=  Create A Session With ClientID  ${client_id}
    Verify A Session Created With ClientID  ${client_id}  ${session_info['Id']}
    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Redfish OBMC Reboot (off)
    Verify A Session Created With ClientID  ${client_id}  ${session_info['Id']}
