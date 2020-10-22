*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/state_manager.robot
Library             ../../lib/bmc_ssh_utils.py

Suite Setup         Suite Setup Execution
Test Setup          Open Connection And Log In
Test Teardown       Test Teardown Execution

*** Test Cases ***

Pre Dump BMC Performance Test
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Pre_Dump_BMC_Performance_Test

    Open Connection And Log In
    Check BMC Performance


Verify User Initiated BMC Dump When Powered Off
    [Documentation]  Create user initiated BMC dump at host off state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Powered_Off

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated Dump
    Check Existence Of BMC Dump File  ${dump_id}


Verify Dump Persistency On Service Restart
    [Documentation]  Create user dump, restart BMC service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Service_Restart

    Delete All BMC Dump
    ${dump_id}=  Create User Initiated Dump
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly.

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Check Existence Of BMC Dump File  ${dump_id}


Verify Dump Persistency On Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_Reset

    Delete All BMC Dump
    ${dump_id}=  Create User Initiated Dump
    OBMC Reboot (off)
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Check Existence Of BMC Dump File  ${dump_id}


Delete User Initiated BMC Dump And Verify
    [Documentation]  Delete user initiated dump and verify.
    [Tags]  Delete_User_Initiated_Dump_And_Verify

    ${dump_id}=  Create User Initiated Dump
    Check Existence Of BMC Dump File  ${dump_id}

    Delete BMC Dump  ${dump_id}


Verify User Initiated Dump Size
    [Documentation]  Verify user Initiated BMC dump size is under 200k.
    [Tags]  Verify_User_Initiated_Dump_Size

    ${dump_id}=  Create User Initiated Dump

    ${dump_size}=  Read Attribute  ${DUMP_ENTRY_URI}${dump_id}  Size
    # Max size for dump is 200k = 200x1024
    Should Be True  0 < ${dump_size} < 204800
    Check Existence Of BMC Dump File  ${dump_id}


Create Two User Initiated Dump And Delete One
    [Documentation]  Create two dumps and delete the first.
    [Tags]  Create_Two_User_Initiated_Dump_And_Delete_One

    ${dump_id_1}=  Create User Initiated Dump
    ${dump_id_2}=  Create User Initiated Dump

    Delete BMC Dump  ${dump_id_1}

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}${dump_id_1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}${dump_id_2}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Check Existence Of BMC Dump File  ${dump_id_2}


Create And Delete BMC Dump Multiple Times
    [Documentation]  Create and delete BMC dump multiple times.
    [Tags]  Create_And_Delete_BMC_Dump_Multiple_Times

    FOR  ${INDEX}  IN  1  5
      ${dump_id}=  Create User Initiated Dump
      Delete BMC Dump  ${dump_id}
    END


Delete All BMC Dumps And Verify
    [Documentation]  Delete all BMC dumps and verify.
    [Tags]  Delete_All_BMC_Dumps_And_Verify

    # Create some dump.
    Create User Initiated Dump
    Create User Initiated Dump

    Delete All BMC Dump
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    Create User Initiated Dump


Verify Core Dump Size
    [Documentation]  Verify BMC core dump size is under 200k.
    [Tags]  Verify_Core_Dump_Size

    Delete All Dumps
    Trigger Core Dump
    Wait Until Keyword Succeeds  2 min  10 sec  Get Dump Entries

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    ${dump_size}=  Read Attribute  ${dump_entries[0]}  Size

    # Max size for dump is 200k = 200x1024
    Should Be True  0 < ${dump_size} < 204800  msg=Size of dump is incorrect.


Dump Out Of Space Test
    [Documentation]  Verify out of dump space is reported when attempt
    ...  to create too many dumps.
    [Tags]  Dump_Out_Of_Space_Test
    [Setup]  Delete All BMC Dump

    # Systems typically hold 8-14 dumps before running out of dump space.
    # Attempt to create too_many_dumps.  Expect to run out of space
    # before this.
    ${too_many_dumps}  Set Variable  ${20}

    # Loop, creating a dump each iteration.  Will either get dump_id or
    # will get EMPTY when out of dump space.
    FOR  ${n}  IN RANGE  0  ${too_many_dumps}
      ${dump_id}=  Create User Initiated Dump  check_out_of_space=${True}
      Exit For Loop If  '${dump_id}' == '${EMPTY}'
      Check Existence Of BMC Dump File  ${dump_id}
    END

    Run Keyword If  '${dump_id}' != '${EMPTY}'  Fail
    ...  msg=Did not run out of dump space as expected.


Post Dump BMC Performance Test
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Post_Dump_BMC_Performance_Test

    Open Connection And Log In
    Check BMC Performance


Post Dump Core Dump Check
    [Documentation]  Check core dump existence on BMC after code update.
    [Tags]  Post_Dump_Core_Dump_Check

    Check For Core Dumps


Verify Dump After Host Watchdog Error Injection
    [Documentation]  Inject host watchdog error and verify whether dump is generated.
    [Tags]  Verify_Dump_After_Host_Watchdog_Error_Injection

    Redfish Power On

    Run Keyword And Ignore Error  Delete All Dumps

    # Enable auto reboot
    Set Auto Reboot  ${1}

    Trigger Host Watchdog Error  2000  30

    Wait Until Keyword Succeeds  300 sec  20 sec  Is Host Rebooted

    #Get dump details
    @{dump_entry_list}=  Read Properties  ${DUMP_ENTRY_URI}

    # Verifing that there is only one dump
    ${length}=  Get length  ${dump_entry_list}
    Should Be Equal As Integers  ${length}  ${1}

    # Get dump id
    ${value}=  Get From List  ${dump_entry_list}  0
    @{split_value}=  Split String  ${value}  /
    ${dump_id}=  Get From List  ${split_value}  -1

    # Max size for dump is 200k = 200x1024
    ${dump_size}=  Read Attribute  ${DUMP_ENTRY_URI}${dump_id}  Size
    Should Be True  0 < ${dump_size} < 204800


Verify Download BMC Dump
    [Documentation]  Verify that a BMC dump can be downloaded to the local machine.
    [Tags]  Verify_Download_BMC_Dump

    ${dump_id}=  Create User Initiated Dump
    ${dump_dict}=  Get Dump Dict
    ${bmc_dump_name}=  Fetch From Right  ${dump_dict['${dump_id}']}  /
    ${bmc_dump_checksum}  ${stderr}  ${rc}=  BMC Execute Command
    ...  md5sum ${dump_dict['${dump_id}']}|awk '{print$1}'
    ${bmc_dump_size}  ${stderr}  ${rc}=  BMC Execute Command
    ...  stat -c "%s" ${dump_dict['${dump_id}']}

    ${response}=  OpenBMC Get Request  ${DUMP_DOWNLOAD_URI}${dump_id}
    ...  quiet=${1}
    Should Be Equal As Strings  ${response.status_code}  ${HTTP_OK}
    Create Binary File  ${EXECDIR}${/}dumps   ${response.content}
    Run  tar -xvf ${EXECDIR}${/}dumps
    ${download_dump_name}=  Fetch From Left  ${bmc_dump_name}  .
    ${download_dump_checksum}=  Run  md5sum ${EXECDIR}/dumps|awk '{print$1}'
    ${download_dump_size}=  Run  stat -c "%s" ${EXECDIR}${/}dumps

    OperatingSystem.Directory Should Exist  ${EXECDIR}/${download_dump_name}
    ...  msg=Created dump name and downloaded dump name don't match.
    Should Be Equal As Strings  ${bmc_dump_checksum}  ${download_dump_checksum}
    Should Be Equal As Strings  ${bmc_dump_size}  ${download_dump_size}

    Run  rm -rf ${EXECDIR}${/}${download_dump_name};rm ${EXECDIR}${/}dumps


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do initial suite setup tasks.

    ${resp}=  OpenBMC Get Request  ${DUMP_URI}
    Run Keyword If  '${resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  Run Keywords  Set Suite Variable  ${DUMP_URI}  /xyz/openbmc_project/dump/  AND
    ...  Set Suite Variable  ${DUMP_ENTRY_URI}  /xyz/openbmc_project/dump/entry/


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Wait Until Keyword Succeeds  3 min  15 sec  Verify No Dump In Progress
    FFDC On Test Case Fail
    Delete All BMC Dump
    Close All Connections
