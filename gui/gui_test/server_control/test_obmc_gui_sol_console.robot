*** Settings ***

Documentation  Test OpenBMC GUI "Serial over LAN Console" sub-menu of "Control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_open_in_new_tab_button}  //button[contains(text(),'Open in new tab')]

*** Test Cases ***

Verify Existence Of All Sections In SOL Console Page
    [Documentation]  Verify existence of all sections in SOL console page.
    [Tags]  Verify_Existence_Of_All_Sections_In_SOL_Console_Page

    Page Should Contain  Access the Serial over LAN console


Verify Existence Of All Buttons In SOL Console Page
    [Documentation]  Verify existence of all buttons in SOL console page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SOL_Console_Page

    Page Should Contain Element  ${xpath_open_in_new_tab_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_sol_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  serial-over-lan
