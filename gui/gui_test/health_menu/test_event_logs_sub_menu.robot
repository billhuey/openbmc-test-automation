*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***
${xpath_event_logs_heading}       //h1[text()="Event logs"]
${xpath_filter_event}             //button[contains(text(),"Filter")]
${xpath_event_severity_ok}        //*[@data-test-id="tableFilter-checkbox-OK"]
${xpath_event_severity_warning}   //*[@data-test-id="tableFilter-checkbox-Warning"]
${xpath_event_severity_critical}  //*[@data-test-id="tableFilter-checkbox-Critical"]
${xpath_event_search}             //input[@placeholder="Search logs"]
${xpath_event_from_date}          //*[@id="input-from-date"]
${xpath_event_to_date}            //*[@id="input-to-date"]
${xpath_select_all_events}        //*[@data-test-id="eventLogs-checkbox-selectAll"]
${xpath_event_action_delete}      //*[@data-test-id="table-button-deleteSelected"]
${xpath_event_action_export}      //*[contains(text(),"Export")]
${xpath_event_action_cancel}      //button[contains(text(),"Cancel")]
${xpath_delete_first_row}         //*[@data-test-id="eventLogs-button-deleteRow-0"][2]
${xpath_confirm_delete}           //button[@class="btn btn-primary"]
${xpath_default_UTC}              //*[@data-test-id='profileSettings-radio-defaultUTC']
${xpath_first_event_id}           //*[@id="table-event-logs"]/tbody/tr[1]/td[2]
${xpath_first_event_date}         //*[@id="table-event-logs"]/tbody/tr[1]/td[5][1]
${xpath_profile_save_button}      //*[@data-test-id='profileSettings-button-saveSettings']

*** Test Cases ***

Verify Navigation To Event Logs Page
    [Documentation]  Verify navigation to Event Logs page.
    [Tags]  Verify_Navigation_To_Event_Logs_Page

    Page Should Contain Element  ${xpath_event_logs_heading}


Verify Existence Of All Buttons In Event Logs Page
    [Documentation]  Verify existence of all buttons in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Event_Logs_Page

    # Types of event severity: OK, Warning, Critical.
    Click Element  ${xpath_filter_event}
    Page Should Contain Element  ${xpath_event_severity_ok}  limit=1
    Page Should Contain Element  ${xpath_event_severity_warning}  limit=1
    Page Should Contain Element  ${xpath_event_severity_critical}  limit=1


Verify Existence Of All Input boxes In Event Logs Page
    [Documentation]  Verify existence of all input boxes in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Event_Logs_Page

    # Search logs.
    Page Should Contain Element  ${xpath_event_search}

    # Date filter.
    Page Should Contain Element  ${xpath_event_from_date}  limit=1
    Page Should Contain Element  ${xpath_event_to_date}  limit=1


Verify Event Log Options
    [Documentation]  Verify all the options after selecting event logs.
    [Tags]  Verify_Click_Event_Options

    Create Error Logs  ${1}
    Select All Events
    Page Should Contain Button  ${xpath_event_action_delete}  limit=1
    Page Should Contain Element  ${xpath_event_action_export}  limit=1
    Page Should Contain Element  ${xpath_event_action_cancel}  limit=1


Select Single Error Log And Delete
    [Documentation]  Select single error log and delete it.
    [Tags]  Select_Single_Error_Log_And_Delete

    Create Error Logs  ${2}
    ${number_of_events_before}=  Get Number Of Event Logs
    Click Element At Coordinates  ${xpath_delete_first_row}  0  0
    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}
    ${number_of_events_after}=  Get Number Of Event Logs
    Should Be Equal  ${number_of_events_before -1}  ${number_of_events_after}
    ...  msg=Failed to delete single error log entry.


Select All Error Logs And Verify Buttons
    [Documentation]  Select all error logs and verify delete, export and cancel buttons.
    [Tags]  Select_All_Error_Logs_And_Verify_Buttons

    Create Error Logs  ${2}
    Wait Until Element Is Visible  ${xpath_delete_first_row}
    Select All Events
    Wait Until Element Is Visible  ${xpath_event_action_delete}
    Element Should Be Visible  ${xpath_event_action_export}
    Element Should Be Visible  ${xpath_event_action_cancel}


Select And Verify Default UTC Timezone For Events
    [Documentation]  Select and verify that default UTC timezone is displayed for an event.
    [Tags]  Select_And_Verify_Default_UTC_Timezone_For_Events
    [Setup]  Redfish.Login
    [Teardown]  Redfish.Logout

    Set Given Timezone In Profile Settings Page

    Navigate To Event Logs Page
    Create Error Logs  ${1}

    ${event_id}=  Get Text  ${xpath_first_event_id}

    # Date format: 2020-12-08\n09:48:38 UTC.
    ${event_date}=  Get Text  ${xpath_first_event_date}
    ${event_day}=  Set Variable  ${event_date.splitlines()[0]}
    ${event_time}=  Set Variable  ${event_date.splitlines()[1]}
    ${event_time}=  Set Variable  ${event_time.split(' UTC')[0]}

    ${error_data}=  Get Event Log Entry  ${event_id}
    # Date format: 2020-12-07T15:18:35+00:00.
    ${redfish_event_date_time}=  Set Variable  ${error_data["Created"].split('T')}

    Should Be Equal  ${event_day}  ${redfish_event_date_time[0]}
    Should Be Equal  ${event_time}  ${redfish_event_date_time[1].split('+')[0]}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Event Logs Page

Navigate To Event Logs Page
    [Documentation]  Navigate to the event logs page from main menu.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_event_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  event-logs

Create Error Logs
    [Documentation]  Create given number of error logs.
    [Arguments]  ${log_count}

    # Description of argument(s):
    # log_count  Number of error logs to create.

    FOR  ${num}  IN RANGE  ${log_count}
        Generate Test Error Log
    END

Select All Events
    [Documentation]  Select all error logs.

    Click Element At Coordinates  ${xpath_select_all_events}  0  0

Set Given Timezone In Profile Settings Page
    [Documentation]  Select the given timezone in profile settings page.
    [Arguments]  ${timezone}=Default

    # Description of argument(s):
    # timezone  Timezone to select (eg. Default or Browser_offset).

    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_profile_settings}
    Click Element At Coordinates    ${xpath_default_UTC}    0    0
	Click Element  ${xpath_profile_save_button}
