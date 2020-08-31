*** Settings ***

Documentation  Test OpenBMC GUI "Server LED" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_server_led_heading}  //h1[text()="Server LED"]
${xpath_led_value}           //*[@data-test-id='serverLed-checkbox-switchIndicatorLed']/following-sibling::label/span
${xpath_overview_led_value}  //*[@data-test-id='overviewQuickLinks-checkbox-serverLed']/following-sibling::label/span

*** Test Cases ***

Verify Navigation To Server LED Page
    [Documentation]  Verify navigation to server LED page.
    [Tags]  Verify_Navigation_To_Server_LED_Page

    Page Should Contain Element  ${xpath_server_led_heading}


Verify Existence Of All Sections In Server LED Page
    [Documentation]  Verify existence of all sections in Server LED page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Server_LED_Page

    Page Should Contain  LED light control


Verify Server Led Sync With Overview Page LED Status
    [Documentation]  Verify server LED sync with overview page LED status.
    [Tags]  Verify_Server_Led_Sync_With_Overview_Page_LED_Status

    ${gui_led_value} =  Get Text  ${xpath_led_value}
    Click Element  ${xpath_overview_menu}
    ${overview_led_value} =  Get Text  ${xpath_overview_led_value}

    Should Be Equal  ${gui_led_value}  ${overview_led_value}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_server_led_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  server-led
