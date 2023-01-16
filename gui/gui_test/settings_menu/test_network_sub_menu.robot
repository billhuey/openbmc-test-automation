*** Settings ***

Documentation   Test OpenBMC GUI "Network" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_network_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_network_heading}                 //h1[text()="Network"]
${xpath_interface_settings}              //h2[text()="Interface settings"]
${xpath_network_settings}                //h2[text()="Network settings"]
${xpath_static_ipv4}                     //h2[text()="IPv4"]
${xpath_static_dns}                      //h2[text()="Static DNS"]
${xpath_domain_name_toggle}              //*[@data-test-id="networkSettings-switch-useDomainName"]
${xpath_dns_servers_toggle}              //*[@data-test-id="networkSettings-switch-useDns"]
${xpath_ntp_servers_toggle}              //*[@data-test-id="networkSettings-switch-useNtp"]
${xpath_add_static_ipv4_address_button}  //button[contains(text(),"Add static IPv4 address")]
${xpath_add_dns_ip_address_button}       //button[contains(text(),"Add IP address")]
${xpath_hostname}                        //*[@title="Edit hostname"]
${xpath_hostname_input}                  //*[@id="hostname"]
${xpath_input_ip_address}                //*[@id="ipAddress"]
${xpath_input_gateway}                   //*[@id="gateway"]
${xpath_input_subnetmask}                //*[@id="subnetMask"]
${xpath_input_static_dns}                //*[@id="staticDns"]
${xpath_cancel_button}                   //button[contains(text(),'Cancel')]
${xpath_delete_dns_server}               //*[@title="Delete DNS address"]

${dns_server}                            10.10.10.10
${test_ipv4_addr}                        10.7.7.7
${test_ipv4_addr_1}                      10.7.7.8
${out_of_range_ip}                       10.7.7.256
${string_ip}                             aa.bb.cc.dd
${negative_ip}                           10.-7.-7.-7
${less_octet_ip}                         10.3.36
${hex_ip}                                0xa.0xb.0xc.0xd
${spl_char_ip}                           @@@.%%.44.11
${test_subnet_mask}                      255.255.0.0
${alpha_netmask}                         ff.ff.ff.ff
${out_of_range_netmask}                  255.256.255.0
${more_byte_netmask}                     255.255.255.0.0
${lowest_netmask}                        128.0.0.0
${test_hostname}                         openbmc

*** Test Cases ***

Verify Navigation To Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page.
    [Tags]  Verify_Navigation_To_Network_Page

    Page Should Contain Element  ${xpath_network_heading}


Verify Existence Of All Sections In Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm the page contains sections that should be accessible.
    [Tags]  Verify_Existence_Of_All_Sections_In_Network_Page

    Wait Until Page Contains Element  ${xpath_network_settings}  timeout=1min
    Page Should Contain Element  ${xpath_interface_settings}
    Page Should Contain Element  ${xpath_static_ipv4}
    Page Should Contain Element  ${xpath_static_dns}


Verify Existence Of All Buttons In Network Page
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm the page contains basic features button that should be accessible.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Network_Page

    Page Should Contain Button  ${xpath_add_static_ipv4_address_button}
    Page Should Contain Button  ${xpath_add_dns_ip_address_button}
    Page Should Contain Button  ${xpath_domain_name_toggle}
    Page Should Contain Button  ${xpath_dns_servers_toggle}
    Page Should Contain Button  ${xpath_ntp_servers_toggle}


Verify Existence Of All Fields In Hostname
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm hostname contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Hostname
    [Teardown]  Run Keywords  Click Button  ${xpath_cancel_button}  AND
    ...  Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_heading}  Network

    Click Element  ${xpath_hostname}
    Wait Until Page Contains  Edit hostname  timeout=1min
    Page Should Contain Textfield  ${xpath_hostname_input}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Fields In Static IP Address
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section static IPv4 contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Static_IP_Address
    [Teardown]  Run Keywords  Click Button  ${xpath_cancel_button}  AND
    ...  Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_heading}  Network

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv4_address_button}
    Wait Until Page Contains  Add static IPv4 address  timeout=15s
    Page Should Contain Textfield  ${xpath_input_ip_address}
    Page Should Contain Textfield  ${xpath_input_gateway}
    Page Should Contain Textfield  ${xpath_input_subnetmask}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Fields In Static DNS
    [Documentation]  Login to GUI and navigate to the settings sub-menu network page
    ...  and confirm section static DNS contains all the fields.
    [Tags]  Verify_Existence_Of_All_Fields_In_Static_DNS
    [Teardown]  Run Keywords  Click Button  ${xpath_cancel_button}  AND
    ...  Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_network_heading}  Network

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_dns_ip_address_button}
    Wait Until Page Contains  Add IP address  timeout=11s
    Page Should Contain Textfield  ${xpath_input_static_dns}
    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Configure And Verify DNS Server Via GUI
    [Documentation]  Login to GUI Network page, add DNS server IP
    ...  and verify that the page reflects server IP.
    [Tags]  Configure_And_Verify_DNS_Server_Via_GUI
    [Teardown]  Delete DNS Servers And Verify

    Add DNS Servers And Verify  ${dns_server}


Configure Static IPv4 Netmask Via GUI And Verify
    [Documentation]  Login to GUI Network page, configure static IPv4 netmask and verify.
    [Tags]  Configure_Static_IPv4_Netmask_Via_GUI_And_Verify
    [Template]  Add Static IP Address And Verify

    # ip_addresses      subnet_masks             gateway          expected_status
    ${test_ipv4_addr}   ${lowest_netmask}        ${default_gateway}  Success
    ${test_ipv4_addr}   ${more_byte_netmask}     ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${alpha_netmask}         ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${out_of_range_netmask}  ${default_gateway}  Invalid format
    ${test_ipv4_addr}   ${test_subnet_mask}      ${default_gateway}  Success


Configure Hostname Via GUI And Verify
    [Documentation]  Login to GUI Network page, configure hostname and verify.
    [Tags]  Configure_Hostname_Via_GUI_And_Verify
    [Teardown]  Configure And Verify Network Settings Via GUI
    ...  ${xpath_hostname}  ${xpath_hostname_input}  ${hostname}

    ${hostname}=  Get BMC Hostname
    Configure And Verify Network Settings Via GUI  ${xpath_hostname}
    ...  ${xpath_hostname_input}  ${test_hostname}

    ${bmc_hostname}=  Get BMC Hostname
    Should Be Equal As Strings  ${bmc_hostname}  ${test_hostname}


Configure And Verify Static IP Address
    [Documentation]  Login to GUI Network page, configure static ip address and verify.
    [Tags]  Configure_And_Verify_Static_IP_Address

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}  ${default_gateway}  Success


Configure And Verify Multiple Static IP Address
    [Documentation]  Login to GUI Network page, configure multiple static IP address and verify.
    [Tags]  Configure_And_Verify_Multiple_Static_IP_Address

    Add Static IP Address And Verify  ${test_ipv4_addr}  ${test_subnet_mask}  ${default_gateway}  Success
    Add Static IP Address And Verify  ${test_ipv4_addr_1}  ${test_subnet_mask}  ${default_gateway}  Success


Configure And Verify Invalid Static IP Address
    [Documentation]  Login to GUI Network page, configure invalid static IP address and verify.
    [Tags]  Configure_And_Verify_Invalid_Static_IP_Address
    [Template]  Add Static IP Address And Verify

    # ip                 subnet_mask          gateway             status
    ${out_of_range_ip}   ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${less_octet_ip}     ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${string_ip}         ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${negative_ip}       ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${hex_ip}            ${test_subnet_mask}  ${default_gateway}  Invalid format
    ${spl_char_ip}       ${test_subnet_mask}  ${default_gateway}  Invalid format

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Wait Until Keyword Succeeds  1 min  15 sec
    ...  Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_network_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  network
    ${default_gateway}=  Get BMC Default Gateway
    Set Suite Variable  ${default_gateway}


Add DNS Servers And Verify
    [Documentation]  Login to GUI Network page,add DNS server on BMC
    ...  and verify it via BMC CLI.
    [Arguments]  ${dns_server}   ${expected_status}=Valid format

    # Description of the argument(s):
    # dns_server           A list of static name server IPs to be
    #                      configured on the BMC.
    # expected_status      Expected status while adding DNS server address
    # ...                  (e.g. Invalid format / Field required).

    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=15sec

    Click Button  ${xpath_add_dns_ip_address_button}
    Input Text  ${xpath_input_static_dns}  ${dns_server}
    Click Button  ${xpath_add_button}
    Run keyword if  '${expected_status}' != 'Valid format'
    ...  Run keywords  Page Should Contain  ${expected_status}  AND  Return From Keyword

    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=10sec
    Wait Until Page Contains  ${dns_server}  timeout=40sec

    # Check if newly added DNS server is configured on BMC.
    ${cli_name_servers}=  CLI Get Nameservers
    ${cmd_status}=  Run Keyword And Return Status
    ...  List Should Contain Sub List  ${cli_name_servers}  ${dns_server}


Delete DNS Servers And Verify
    [Documentation]  Login to GUI Network page,delete static name servers
    ...  and verify that page does not reflect static name servers.

    Page Should Contain Element  ${xpath_delete_dns_server}
    Wait Until Element Is Enabled  ${xpath_delete_dns_server}
    Click Button  ${xpath_delete_dns_server}
    Wait Until Page Contains Element  ${xpath_add_dns_ip_address_button}  timeout=15
    # Check if all name servers deleted on BMC.
    ${nameservers}=  CLI Get Nameservers
    Should Be Empty  ${nameservers}


Add Static IP Address And Verify
    [Documentation]  Add static IP address, subnet mask and
    ...  gateway via GUI and verify.
    [Arguments]  ${ip_address}  ${subnet_mask}  ${gateway_address}  ${expected_status}=error

    # Description of argument(s):
    # ip_address          IP address to be added (e.g. 10.7.7.7).
    # subnet_mask         Subnet mask for the IP to be added (e.g. 255.255.0.0).
    # gateway_address     Gateway address for the IP to be added (e.g. 10.7.7.1).
    # expected_status     Expected status while adding static ipv4 address
    # ....                (e.g. Invalid format / Field required).

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_add_static_ipv4_address_button}

    Input Text  ${xpath_input_ip_address}  ${ip_address}
    Input Text  ${xpath_input_subnetmask}  ${subnet_mask}
    Input Text  ${xpath_input_gateway}  ${gateway_address}

    Click Element  ${xpath_add_button}
    Run Keyword If  '${expected_status}' == 'Success'
    ...  Run Keywords  Wait Until Page Contains  ${ip_address}  timeout=40sec
    ...  AND  Validate Network Config On BMC

    ...  ELSE IF  '${expected_status}' == 'Invalid format'
    ...  Run Keywords  Page Should Contain  Invalid format  AND
    ...  Click Button  ${xpath_cancel_button}


Configure And Verify Network Settings Via GUI
    [Documentation]  Configure and verify network settings via GUI.
    [Arguments]  ${xpath_nw_settings}  ${xpath_nw_settings_input_field}  ${input_value}

    # Description of argument(s):
    # xpath_nw_settings               xpath of the network settings.
    # xpath_nw_settings_input_field   xpath of the network setting's input field.
    # input_value                     Input value for configuration. E.g. hostname, IP etc.

    Wait Until Keyword Succeeds  30 sec  10 sec  Click Element  ${xpath_nw_settings}
    Input Text  ${xpath_nw_settings_input_field}  ${input_value}
    Click Button  ${xpath_add_button}
    Wait Until Page Contains  ${input_value}  timeout=30sec
