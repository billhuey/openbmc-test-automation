*** Settings ***

Documentation       eSEL's Test cases.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Variables           ../data/variables.py
Resource            ../lib/utils.robot

Suite Setup         eSEL Test SetUp
Suite Teardown      Test Cleanup On Exit
Test Teardown       FFDC On Test Case Fail
Test Setup          Delete Error logs

Force Tags  eSEL_Logging

*** Variables ***

${RESERVE_ID}       raw 0x0a 0x42
${RAW_PREFIX}       raw 0x32 0xf0 0x

${RAW_SUFFIX}       0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x00
...  0xdf 0x00 0x00 0x00 0x00 0x20 0x00 0x04 0x12 0x35 0x6f 0xaa 0x00 0x00

${RAW_SEL_COMMIT}   raw 0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20
...  0x00 0x04 0x12 0x35 0x6f 0x02 0x00 0x01

${LOGGING_SERVICE}  xyz.openbmc_project.Logging.service

${ESEL_DATA}        ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00

*** Test Cases ***

Verify eSEL Using REST
    [Documentation]  Generate eSEL log and verify using REST.
    [Tags]  Verify_eSEL_Using_REST

    Create eSEL
    # New eSEL log should exist
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list
#    ${resp}=  Get URL List  /xyz/openbmc_project/logging/entry
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Verify eSEL Entries Using REST
    [Documentation]  Verify that eSEL entries have data.
    [Tags]  Verify_eSEL_Entries_Using_REST

    Create eSEL
    Verify eSEL Entries


Verify Multiple eSEL Using REST
    [Documentation]  Generate multiple eSEL log and verify using REST.
    [Tags]  Verify_Multiple_eSEL_Using_REST

    Create eSEL
    Create eSEL
    ${entries}=  Count eSEL Entries
    Should Be Equal As Integers  ${entries}  ${2}


Check eSEL AdditionalData
    [Documentation]  Generate eSEL log and verify AdditionalData is
    ...              not empty.
    [Tags]  Check_eSEL_AdditionalData

    Create eSEL
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    # "/xyz/openbmc_project/logging/entry/1": {
    #    "Timestamp": 1487743771812,
    #    "AdditionalData": [],
    #    "Message": "org.open_power.Error.Host.Event.Event",
    #    "Id": 1,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency"
    # }
    Should Not Be Empty  ${jsondata["data"]["AdditionalData"]}

Test Wrong Reservation_ID
    [Documentation]   This testcase is to test BMC can handle multi-requestor's
    ...               oem partial add command with incorrect reservation id.
    ...               It simulates sending partial add command with fake content
    ...                and wrong Reservation ID. This command will be rejected.
    [Tags]  Test_Wrong_Reservation_ID

    ${rev_id_1}=   Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_1}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_1}   -2
    Run Inband IPMI Raw Command   0x0a 0x42
    ${output}=     Check IPMI OEMpartialadd Reject  0x32 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Contain   ${output}   Reservation cancelled

Test Correct Reservation_ID
    [Documentation]   This testcase is to test BMC can handle multi-requestor's
    ...               oem partial add command with correct reservation id. It
    ...                simulates sending partial add command with fake content
    ...               and correct Reservation ID. This command will be accepted.
    [Tags]  Test_Correct_Reservation_ID

    Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_2}=    Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_2}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_2}   -2
    ${output}=      Check IPMI OEMpartialadd Accept  0x32 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Be Empty    ${output}

Clear Test File
   [Documentation]   Clear /tmp/esel
   [Tags]  Clear_Test_File

   Execute Command   rm /tmp/esel
   Execute Command   sync

*** Keywords ***

Create eSEL
    [Documentation]  Create an eSEL.
    Open Connection And Log In
    ${Resv_id}=  Run Inband IPMI Standard Command  ${RESERVE_ID}
    ${cmd}=  Catenate
    ...  ${RAW_PREFIX}${Resv_id.strip().rsplit(' ', 1)[0]}  ${RAW_SUFFIX}
    Run Inband IPMI Standard Command  ${cmd}
    Run Inband IPMI Standard Command  ${RAW_SEL_COMMIT}

Count eSEL Entries
    [Documentation]  Count eSEL entries logged.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    ${count}=  Get Length  ${jsondata["data"]}
    [Return]  ${count}


Verify eSEL Entries
    [Documentation]  Verify eSEL entries logged.
    ${elog_entry}=  Get URL List  /xyz/openbmc_project/logging/entry
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  message
    Should Be Equal  ${entry_id}
    ...  org.open_power.Error.Host.Event.Event
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Severity
    Should Be Equal  ${entry_id}
    ...  xyz.openbmc_project.Logging.Entry.Level.Informational 
#    ...  xyz.openbmc_project.Logging.Entry.Level.Error
#    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}
#    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
#    ${jsondata}=  To JSON  ${resp.content}
    #  "data": {
    #       "AdditionalData": [
    #           "ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00 "
    #          ],
    #       "Id": 1,
    #       "Message": "org.open_power.Error.Host.Event.Event",
    #       "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency",
    #       "Timestamp": 1485904869061
    # }

#    Should Be Equal As Integers  ${jsondata["data"]["Id"]}  ${1}
#    Should Be Equal As Strings
#    ...  ${jsondata["data"]["AdditionalData"][0].rstrip()}  ${ESEL_DATA}


Test Cleanup On Exit
    [Documentation]  Cleanup test logs and connection.
    Close All Connections


Restart Logging Service
    [Documentation]  Restart Logging to clear eSEL log.
    ${MainPID}  ${stderr}=  Execute Command
    ...  systemctl restart ${LOGGING_SERVICE}  return_stderr=True
    Should Be Empty  ${stderr}

    Sleep  10s  reason=Wait for service to restart properly.

Run IPMI Command Returned
    [Arguments]    ${args}
    ${output_1}=    Execute Command   /tmp/ipmitool -I dbus raw ${args}
    [Return]    ${output_1}

Check IPMI OEMpartialadd Reject
    [Arguments]    ${args}
    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_2}=  Execute Command  ipmitool raw ${args}
    ...        return_stdout=True  return_stderr=True  return_rc=True
    [Return]  ${stderr}

eSEL Test SetUp
    [Documentation]  Validates input parameters & check if HOST OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Open Connection And Log In

Check IPMI OEMpartialadd Accept
    [Arguments]    ${args}
    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_3}=  Execute Command  ipmitool raw ${args}
    ...         return_stdout=True  return_stderr=True  return_rc=True
    Should Be Equal  ${output_3}  ${0}  msg=${stderr}
    [Return]  ${stderr}

