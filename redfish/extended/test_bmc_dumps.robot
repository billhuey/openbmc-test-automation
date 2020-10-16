*** Settings ***

Documentation       Test BMC dump functionality of OpenBMC.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/dump_utils.robot

Test Setup          Redfish Delete All BMC Dumps
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify User Initiated BMC Dump When Host Powered Off
    [Documentation]  Create user initiated BMC dump at host off state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Powered_Off

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify Dump Persistency On Dump Service Restart
    [Documentation]  Create user dump, restart dump manager service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Dump_Service_Restart

    Create User Initiated BMC Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Restart dump service.
    BMC Execute Command  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly

    ${dump_entries_after}=  Get BMC Dump Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Verify Dump Persistency On BMC Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_BMC_Reset

    Create User Initiated BMC Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Reset BMC.
    OBMC Reboot (off)

    ${dump_entries_after}=  Get BMC Dump Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


*** Keywords ***

Create User Initiated BMC Dump
    [Documentation]  Generate user initiated BMC dump and return the dump id number (e.g., "5").

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  Redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    # Example of response from above Redfish POST request.
    # "@odata.id": "/redfish/v1/TaskService/Tasks/0",
    # "@odata.type": "#Task.v1_4_3.Task",
    # "Id": "0",
    # "TaskState": "Running",
    # "TaskStatus": "OK"

    Wait Until Keyword Succeeds  5 min  15 sec  Is Task Completed  ${resp.dict['Id']}
    ${task_id}=  Set Variable  ${resp.dict['Id']}

    ${task_details}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    ${http_headers}=  Set Variable  ${task_details["Payload"]["HttpHeaders"]}

    # Example of HttpHeaders field of task details.
    # "Payload": {
    #   "HttpHeaders": [
    #     "Host: <BMC_IP>",
    #      "Accept-Encoding: identity",
    #      "Connection: Keep-Alive",
    #      "Accept: */*",
    #      "Content-Length: 33",
    #      "Location: /redfish/v1/Managers/bmc/LogServices/Dump/Entries/2"]
    #    ],
    #    "HttpOperation": "POST",
    #    "JsonBody": "{\"DiagnosticDataType\":\"Manager\"}",
    #     "TargetUri": "/redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
    # }

    ${dump_location}=  Get Matches  ${http_headers}  Location*
    ${dump_id}=  Fetch From Right  ${dump_location[0]}  /

    [Return]  ${dump_id}


Is Task Completed
    [Documentation]  Verify if the given task is completed.
    [Arguments]   ${task_id}

    # Description of argument(s):
    # task_id        Id of task which needs to be checked.

    ${task_details}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    Should Be Equal As Strings  ${task_details['TaskState']}  Completed


Get BMC Dump Entries
    [Documentation]  Return list of dump entries.

    ${dump_id_list}=  Create List
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc/LogServices/Dump/Entries

    FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
      ${dump_uri}=  Set Variable  ${resp.dict["Members"][${entry}]["@odata.id"]}
      ${dump_id}=  Fetch From Right  ${dump_uri}  /
      Append To List  ${dump_id_list}  ${dump_id}
    END

    [Return]  ${dump_id_list}


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections

