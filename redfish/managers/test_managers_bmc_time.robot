*** Settings ***
Documentation       Test BMC manager time functionality.

Resource            ../../lib/resource.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/common_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/rest_client.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution

Test Tags           managers_bmc_time


*** Variables ***
${max_time_diff_in_seconds}     6
# The "offset" consists of the value "26" specified for hours.    Redfish will
# convert that to the next day + 2 hours.
${date_time_with_offset}        2019-04-25T26:24:46+00:00
${expected_date_time}           2019-04-26T02:24:46+00:00
${invalid_datetime}             "2019-04-251T12:24:46+00:00"
${ntp_server_1}                 9.9.9.9
${ntp_server_2}                 2.2.3.3
&{original_ntp}                 &{EMPTY}
${year_without_ntp}             1970


*** Test Cases ***
Verify Redfish BMC Time
    [Documentation]    Verify that date/time obtained via redfish matches
    ...    date/time obtained via BMC command line.
    [Tags]    verify_redfish_bmc_time

    ${redfish_date_time}=    Redfish Get DateTime
    ${cli_date_time}=    CLI Get BMC DateTime
    ${time_diff}=    Subtract Date From Date    ${cli_date_time}
    ...    ${redfish_date_time}
    ${time_diff}=    Evaluate    abs(${time_diff})
    Rprint Vars    redfish_date_time    cli_date_time    time_diff
    Should Be True    ${time_diff} < ${max_time_diff_in_seconds}
    ...    The difference between Redfish time and CLI time exceeds the allowed time difference.

Verify Set Time Using Redfish
    [Documentation]    Verify set time using redfish API.
    [Tags]    verify_set_time_using_redfish

    Set Time To Manual Mode

    ${old_bmc_time}=    CLI Get BMC DateTime
    # Add 3 days to current date.
    ${new_bmc_time}=    Add Time to Date    ${old_bmc_time}    3 Days
    Redfish Set DateTime    ${new_bmc_time}
    ${cli_bmc_time}=    CLI Get BMC DateTime
    ${time_diff}=    Subtract Date From Date    ${cli_bmc_time}
    ...    ${new_bmc_time}
    ${time_diff}=    Evaluate    abs(${time_diff})
    Rprint Vars    old_bmc_time    new_bmc_time    cli_bmc_time    time_diff    max_time_diff_in_seconds
    Should Be True    ${time_diff} < ${max_time_diff_in_seconds}
    ...    The difference between Redfish time and CLI time exceeds the allowed time difference.
    # Setting back to old bmc time.
    Redfish Set DateTime    ${old_bmc_time}

Verify Set DateTime With Offset Using Redfish
    [Documentation]    Verify set DateTime with offset using redfish API.
    [Tags]    verify_set_datetime_with_offset_using_redfish

    Redfish Set DateTime    ${date_time_with_offset}
    ${cli_bmc_time}=    CLI Get BMC DateTime

    ${date_time_diff}=    Subtract Date From Date    ${cli_bmc_time}
    ...    ${expected_date_time}    exclude_millis=yes
    ${date_time_diff}=    Convert to Integer    ${date_time_diff}
    Rprint Vars    date_time_with_offset    expected_date_time    cli_bmc_time
    ...    date_time_diff    max_time_diff_in_seconds
    Valid Range    date_time_diff    0    ${max_time_diff_in_seconds}
    [Teardown]    Run Keywords    Redfish Set DateTime    AND    FFDC On Test Case Fail

Verify Set DateTime With Invalid Data Using Redfish
    [Documentation]    Verify error while setting invalid DateTime using Redfish.
    [Tags]    verify_set_datetime_with_invalid_data_using_redfish

    Redfish Set DateTime    ${invalid_datetime}    valid_status_codes=[${HTTP_BAD_REQUEST}]

Verify DateTime Persists After Reboot
    [Documentation]    Verify date persists after BMC reboot.
    [Tags]    verify_datetime_persists_after_reboot

    # Synchronize BMC date/time to local system date/time.
    ${local_system_time}=    Get Current Date
    Redfish Set DateTime    ${local_system_time}
    Redfish OBMC Reboot (off)
    Redfish.Login
    ${bmc_time}=    CLI Get BMC DateTime
    ${local_system_time}=    Get Current Date
    ${time_diff}=    Subtract Date From Date    ${bmc_time}
    ...    ${local_system_time}
    ${time_diff}=    Evaluate    abs(${time_diff})
    Rprint Vars    local_system_time    bmc_time    time_diff    max_time_diff_in_seconds
    Should Be True    ${time_diff} < ${max_time_diff_in_seconds}
    ...    The difference between Redfish time and CLI time exceeds the allowed time difference.

Verify NTP Server Set
    [Documentation]    Patch NTP servers and verify NTP servers is set.
    [Tags]    verify_ntp_server_set
    [Setup]    Set NTP state    ${True}

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}
    ...    body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_2}']}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # NTP network take few seconds to reload.
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify NTP Servers Are Populated

Verify NTP Server Value Not Duplicated
    [Documentation]    Verify NTP servers value not same for both primary and secondary server.
    [Tags]    verify_ntp_server_value_not_duplicated

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}
    ...    body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_1}']}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${network_protocol}=    Redfish.Get Properties    ${REDFISH_NW_PROTOCOL_URI}
    Should Contain X Times    ${network_protocol["NTP"]["NTPServers"]}    ${ntp_server_1}    1
    ...    msg=NTP primary and secondary server values should not be same.

Verify NTP Server Setting Persist After BMC Reboot
    [Documentation]    Verify NTP server setting persist after BMC reboot.
    [Tags]    verify_ntp_server_setting_persist_after_bmc_reboot
    [Setup]    Set NTP state    ${True}

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}
    ...    body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_2}']}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Redfish OBMC Reboot (off)
    Redfish.Login

    # NTP network take few seconds to reload.
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify NTP Servers Are Populated

Verify Enable NTP
    [Documentation]    Verify NTP protocol mode can be enabled.
    [Tags]    verify_enable_ntp

    ${original_ntp}=    Redfish.Get Attribute    ${REDFISH_NW_PROTOCOL_URI}    NTP
    Set Suite Variable    ${original_ntp}
    Rprint Vars    original_ntp
    # The following patch command should set the ["NTP"]["ProtocolEnabled"] property to "True".
    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body={'NTP':{'ProtocolEnabled': ${True}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Wait Until Keyword Succeeds    1 min    5 sec
    ...    Verify System Time Sync Status    ${True}
    ${ntp}=    Redfish.Get Attribute    ${REDFISH_NW_PROTOCOL_URI}    NTP
    Rprint Vars    ntp
    Valid Value    ntp["ProtocolEnabled"]    valid_values=[True]
    [Teardown]    Restore NTP Mode

Verify Immediate Consumption Of BMC Date
    [Documentation]    Verify immediate change in BMC date time.
    [Tags]    verify_immediate_consumption_of_bmc_date
    [Template]    Set BMC Date And Verify
    [Setup]    Run Keywords    Set Time To Manual Mode    AND
    ...    Redfish Set DateTime    valid_status_codes=[${HTTP_OK}]

    # host_state
    on
    off
    [Teardown]    Run Keywords    FFDC On Test Case Fail    AND
    ...    Redfish Set DateTime    valid_status_codes=[${HTTP_OK}]

Verify Set DateTime With NTP Enabled
    [Documentation]    Verify whether set managers dateTime is restricted with NTP enabled.
    [Tags]    verify_set_datetime_with_ntp_enabled

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body={'NTP':{'ProtocolEnabled': ${True}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${ntp}=    Redfish.Get Attribute    ${REDFISH_NW_PROTOCOL_URI}    NTP
    Valid Value    ntp["ProtocolEnabled"]    valid_values=[True]
    ${local_system_time}=    Get Current Date
    Redfish Set DateTime    ${local_system_time}
    ...    valid_status_codes=[${HTTP_BAD_REQUEST}, ${HTTP_INTERNAL_SERVER_ERROR}]


*** Keywords ***
Test Teardown Execution
    [Documentation]    Do the post test teardown.

    FFDC On Test Case Fail

Redfish Get DateTime
    [Documentation]    Returns BMC Datetime value from Redfish.

    ${date_time}=    Redfish.Get Attribute    ${REDFISH_BASE_URI}Managers/${MANAGER_ID}    DateTime
    RETURN    ${date_time}

Redfish Set DateTime
    [Documentation]    Set DateTime using Redfish.
    [Arguments]    ${date_time}=${EMPTY}    &{kwargs}
    # Description of argument(s):
    # date_time    New time to set for BMC (eg.
    #    "2019-06-30 09:21:28"). If this value is
    #    empty, it will be set to the UTC current
    #    date time of the local system.
    # kwargs    Additional parameters to be passed directly to
    #    th Redfish.Patch function.    A good use for
    #    this is when testing a bad date-time, the
    #    caller can specify
    #    valid_status_codes=[${HTTP_BAD_REQUEST}].

    # Assign default value of UTC current date time if date_time is empty.
    IF    '${date_time}' == '${EMPTY}'
        ${date_time}=    Get Current Date    time_zone=UTC
    ELSE
        ${date_time}=    Set Variable    ${date_time}
    END
    Wait Until Keyword Succeeds    1min    5sec
    ...    Redfish.Patch    ${REDFISH_BASE_URI}Managers/${MANAGER_ID}    body={'DateTime': '${date_time}'}    &{kwargs}

Set Time To Manual Mode
    [Documentation]    Set date time to manual mode via Redfish.

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body={'NTP':{'ProtocolEnabled': ${False}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Restore NTP Mode
    [Documentation]    Restore the original NTP mode.

    IF    &{original_ntp} == &{EMPTY}    RETURN
    Print Timen    Restore NTP Mode.
    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}
    ...    body={'NTP':{'ProtocolEnabled': ${original_ntp["ProtocolEnabled"]}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Suite Setup Execution
    [Documentation]    Do the suite level setup.

    Printn
    Redfish.Login
    Get NTP Initial Status
    ${old_date_time}=    CLI Get BMC DateTime
    ${year_status}=    Run Keyword And Return Status    Should Not Contain    ${old_date_time}    ${year_without_ntp}
    IF    ${year_status} == False    Enable NTP And Add NTP Address
    Set Time To Manual Mode

Suite Teardown Execution
    [Documentation]    Do the suite level teardown.

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}
    ...    body={'NTP':{'NTPServers': ['${EMPTY}', '${EMPTY}']}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Set Time To Manual Mode
    Restore NTP Status
    Redfish.Logout

Set NTP state
    [Documentation]    Set NTP service inactive.
    [Arguments]    ${state}

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body={'NTP':{'ProtocolEnabled': ${state}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Get NTP Initial Status
    [Documentation]    Get NTP service Status.

    ${original_ntp}=    Redfish.Get Attribute    ${REDFISH_NW_PROTOCOL_URI}    NTP
    Set Suite Variable    ${original_ntp}

Restore NTP Status
    [Documentation]    Restore NTP Status.

    IF    '${original_ntp["ProtocolEnabled"]}' == 'True'
        Set NTP state    ${TRUE}
    ELSE
        Set NTP state    ${FALSE}
    END

Set BMC Date And Verify
    [Documentation]    Set BMC Date Time at a given host state and verify.
    [Arguments]    ${host_state}
    # Description of argument(s):
    # host_state    Host state at which date time will be updated for verification
    #    (eg. on, off).

    IF    '${host_state}' == 'on'
        Redfish Power On    stack_mode=skip
    ELSE
        Redfish Power off    stack_mode=skip
    END
    ${current_date}=    Get Current Date    time_zone=UTC
    ${new_value}=    Subtract Time From Date    ${current_date}    1 day
    Redfish Set DateTime    ${new_value}    valid_status_codes=[${HTTP_OK}]
    ${current_value}=    Redfish Get DateTime
    ${time_diff}=    Subtract Date From Date    ${current_value}    ${new_value}
    Should Be True    '${time_diff}'<='3'

Verify NTP Servers Are Populated
    [Documentation]    Redfish GET request /redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol response
    ...    and verify if NTP servers are populated.

    ${network_protocol}=    Redfish.Get Properties    ${REDFISH_NW_PROTOCOL_URI}
    Should Contain    ${network_protocol["NTP"]["NTPServers"]}    ${ntp_server_1}
    ...    msg=NTP server value ${ntp_server_1} not stored.
    Should Contain    ${network_protocol["NTP"]["NTPServers"]}    ${ntp_server_2}
    ...    msg=NTP server value ${ntp_server_2} not stored.

Verify System Time Sync Status
    [Documentation]    Verify the status of service systemd-timesyncd matches the NTP protocol enabled state.
    [Arguments]    ${expected_sync_status}=${True}

    # Description of argument(s):
    # expected_sync_status    expected status at which NTP protocol enabled will be updated for verification
    #    (eg. True, False).

    ${resp}=    BMC Execute Command
    ...    systemctl status systemd-timesyncd
    ...    ignore_err=${1}
    ${sync_status}=    Get Lines Matching Regexp    ${resp[0]}    .*Active.*
    IF    ${expected_sync_status}==${True}
        Should Contain    ${sync_status}    active (running)
    END
    IF    ${expected_sync_status}==${False}
        Should Contain    ${sync_status}    inactive (dead)
    END

Enable NTP And Add NTP Address
    [Documentation]    Enable NTP Protocol and Add NTP Address.

    Set NTP state    ${TRUE}

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body={'NTP':{'NTPServers': ${NTP_SERVER_ADDRESSES}}}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Wait Until Keyword Succeeds    1 min    10 sec    Check Date And Time Was Changed

Check Date And Time Was Changed
    [Documentation]    Verify date was current date and time.

    ${new_date_time}=    CLI Get BMC DateTime
    Should Not Contain    ${new_date_time}    ${year_without_ntp}
