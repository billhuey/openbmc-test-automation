*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Security and Access" menu.

Resource         ../../lib/gui_resource.robot
Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_policies_heading}       //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}         //*[@data-test-id='policies-toggle-bmcShell']/following-sibling::label
${xpath_network_ipmi_toggle}    //*[@data-test-id='polices-toggle-networkIpmi']


*** Test Cases ***

Verify Navigation To Policies Page
    [Documentation]  Verify navigation to policies page.
    [Tags]  Verify_Navigation_To_Policies_Page

    Page Should Contain Element  ${xpath_policies_heading}


Verify Existence Of All Sections In Policies Page
    [Documentation]  Verify existence of all sections in policies page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Policies_Page

    Page Should Contain  Network services
    Page Should Contain  BMC shell (via SSH)
    Page Should Contain  Network IPMI (out-of-band IPMI)


Verify Existence Of All Buttons In Policies Page
    [Documentation]  Verify existence of All Buttons in policies page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Policies_Page

    Page Should Contain Element  ${xpath_bmc_ssh_toggle}
    Page Should Contain Element  ${xpath_network_ipmi_toggle}


Enable SSH Via GUI And Verify
    [Documentation]  Verify that SSH to BMC starts working after enabling SSH.
    [Tags]  Enable_SSH_Via_GUI_And_Verify
    [Teardown]  Run Keywords  Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol
    ...  body={"SSH":{"ProtocolEnabled":True}}  valid_status_codes=[200, 204]  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec  Open Connection And Login

    # Disable ssh via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":False}}
    ...   valid_status_codes=[200, 204]

    # Wait for GUI to reflect disable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Disabled

    # Enable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}

    # Wait for GUI to reflect enable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Enabled

    Wait Until Keyword Succeeds  10 sec  5 sec  Open Connection And Login


Disable SSH Via GUI And Verify
    [Documentation]  Verify that SSH to BMC stops working after disabling SSH.
    [Tags]  Disable_SSH_Via_GUI_And_Verify
    [Teardown]  Run Keywords  Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol
    ...  body={"SSH":{"ProtocolEnabled":True}}  valid_status_codes=[200, 204]  AND
    ...  Wait Until Keyword Succeeds  30 sec  5 sec  Open Connection And Login

    # Enable ssh via Redfish.
    Redfish.Patch  /redfish/v1/Managers/bmc/NetworkProtocol  body={"SSH":{"ProtocolEnabled":True}}
    ...   valid_status_codes=[200, 204]

    # Wait for GUI to reflect enable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Enabled

    # Disable ssh via GUI.
    Click Element  ${xpath_bmc_ssh_toggle}

    # Wait for GUI to reflect disable SSH status.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_bmc_ssh_toggle}  Disabled

    ${status}=  Run Keyword And Return Status
    ...  Wait Until Keyword Succeeds  10 sec  5 sec  Open Connection And Login

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.
    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  policies


