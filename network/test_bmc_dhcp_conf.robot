*** Settings ***
Documentation          DHCP Network to test suite functionality.

Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/bmc_network_utils.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/bmc_network_utils.py

Suite Setup            Suite Setup Execution
Suite Teardown         Redfish.Logout

*** Test Cases ***

Enable DHCP Via Redfish And Verify
    [Documentation]  Enable DHCP via Redfish and verify.
    [Tags]  Enable_DHCP_Via_Redfish_And_Verify
    [Teardown]  Run Keywords  Restore Configuration
    ...  AND  FFDC On Test Case Fail

    ${active_channel_config}=  Get Active Channel Config
    Redfish.Patch
    ...  /redfish/v1/Managers/bmc/EthernetInterfaces/${active_channel_config['${CHANNEL_NUMBER}']['name']}/
    ...  body={"DHCPv4":{"DHCPEnabled":${True}}}

    ${resp}=  Redfish.Get  ${REDFISH_NW_ETH0_URI}
    Should Be Equal As Strings  ${resp.dict["DHCPv4"]["DHCPEnabled"]}  ${True}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    # This keyword should login to host OS.
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipsrc static  login_host=${1}

    ${host_name}  ${ip_address}=  Get Host Name IP  host=${OPENBMC_HOST}

    Set Suite Variable  ${ip_address}

    @{network_configurations}=  Get Network Configuration
    FOR  ${network_configuration}  IN  @{network_configurations}
      Run Keyword If  '${network_configuration['Address']}' == '${ip_address}'
      ...  Set Suite Variable  ${subnet_mask}  ${network_configuration['SubnetMask']}
    END

    ${initial_lan_config}=  Get LAN Print Dict  ${CHANNEL_NUMBER}  ipmi_cmd_type=inband
    Set Suite Variable  ${initial_lan_config}


Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard in-band IPMI command and set
    ...              the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}

    # Description of argument(s):
    # ip       The IP address to be set using ipmitool-inband.
    # netmask  The Netmask to be set using ipmitool-inband.
    # gateway  The Gateway address to be set using ipmitool-inband.
    # login    Indicates that this keyword should login to host OS.

    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} ipaddr ${ip}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} netmask ${netmask}  login_host=${0}
    Run Inband IPMI Standard Command
    ...  lan set ${CHANNEL_NUMBER} defgw ipaddr ${gateway}  login_host=${0}


Restore Configuration
    [Documentation]  Restore the configuration to its pre-test state.

    ${length}=  Get Length  ${initial_lan_config}
    Return From Keyword If  ${length} == ${0}

    Set IPMI Inband Network Configuration  ${ip_address}  ${subnet_mask}
    ...  ${initial_lan_config['Default Gateway IP']}

