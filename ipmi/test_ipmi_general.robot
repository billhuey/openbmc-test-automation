*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py
Variables        ../data/ipmi_variable.py
Library          ../lib/bmc_network_utils.py
Library          ../lib/ipmi_utils.py

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Get DCMI Capabilities
    [Documentation]  Verify get DCMI capabilities command output.
    [Tags]  Verify_Get_DCMI_Capabilities
    ${cmd_output}=  Run IPMI Standard Command  dcmi discover

    @{supported_capabilities}=  Create List
    # Supported DCMI capabilities:
    ...  Mandatory platform capabilties
    ...  Optional platform capabilties
    ...  Power management available
    ...  Managebility access capabilties
    ...  In-band KCS channel available
    # Mandatory platform attributes:
    ...  200 SEL entries
    ...  SEL automatic rollover is enabled
    # Optional Platform Attributes:
    ...  Slave address of device: 0h (8bits)(Satellite/External controller)
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: 1 is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    FOR  ${capability}  IN  @{supported_capabilities}
      Should Contain  ${cmd_output}  ${capability}  ignore_case=True
      ...  msg=Supported DCMI capabilities not present.
    END


Test Get Self Test Results via IPMI Raw Command
    [Documentation]  Get self test results via IPMI raw command and verify the output.
    [Tags]  Test_Get_Self_Test_Results_via_IPMI

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Self_Test_Results']['Get'][0]}

    # 55h = No error. All Self Tests Passed.
    # 56h = Self Test function not implemented in this controller.
    Should Contain Any  ${resp}  55 00  56 00


Test Get Device GUID Via IPMI Raw Command
    [Documentation]  Get device GUID via IPMI raw command and verify it using Redfish.
    [Tags]  Test_Get_Device_GUID_via_IPMI_and_Verify_via_Redfish
    [Teardown]  Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail
    # Get GUIDS via IPMI.
    # This should match the /redfish/v1/Managers/bmc's UUID data.
    ${guids}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Device GUID']['Get'][0]}
    # Reverse the order and remove space delims.
    ${guids}=  Split String  ${guids}
    Reverse List  ${guids}
    ${guids}=  Evaluate  "".join(${guids})

    Redfish.Login
    ${uuid}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  UUID
    ${uuid}=  Remove String  ${uuid}  -

    Rprint Vars  guids  uuid
    Valid Value  uuid  ['${guids}']


Verify Get Channel Info via IPMI
    [Documentation]  Verify get channel info via IPMI.
    [Tags]  Verify_Get_Channel_Info_via_IPMI

    # Get channel info via ipmi command "ipmitool channel info [channel number]".
    # Verify channel info with files "channel_access_volatile.json", "channel_access_nv.json"
    # and "channel_config.json" in BMC.

    # Example output from 'Get Channel Info':
    # channel_info:
    #   [channel_0x2_info]:
    #     [channel_medium_type]:                        802.3 LAN
    #     [channel_protocol_type]:                      IPMB-1.0
    #     [session_support]:                            multi-session
    #     [active_session_count]:                       0
    #     [protocol_vendor_id]:                         7154
    #   [volatile(active)_settings]:
    #       [alerting]:                                 enabled
    #       [per-message_auth]:                         enabled
    #       [user_level_auth]:                          enabled
    #       [access_mode]:                              always available
    #   [Non-Volatile Settings]:
    #       [alerting]:                                 enabled
    #       [per-message_auth]:                         enabled
    #       [user_level_auth]:                          enabled
    #       [access_mode]:                              always available

    ${channel_info_ipmi}=  Get Channel Info  ${CHANNEL_NUMBER}
    ${active_channel_config}=  Get Active Channel Config
    ${channel_volatile_data_config}=  Get Channel Access Config  /run/ipmi/channel_access_volatile.json
    ${channel_nv_data_config}=  Get Channel Access Config  /var/lib/ipmi/channel_access_nv.json

    Rprint Vars  channel_info_ipmi  active_channel_config  channel_volatile_data_config  channel_nv_data_config

    Valid Value  medium_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_medium_type']}']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['medium_type']}']

    Valid Value  protocol_type_ipmi_conf_map['${channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['channel_protocol_type']}']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['protocol_type']}']

    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['session_support']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['channel_info']['session_supported']}']

    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['active_session_count']
    ...  ['${active_channel_config['${CHANNEL_NUMBER}']['active_sessions']}']
    # IPMI Spec: The IPMI Enterprise Number is: 7154 (decimal)
    Valid Value  channel_info_ipmi['channel_0x${CHANNEL_NUMBER}_info']['protocol_vendor_id']  ['7154']

    # Verify volatile(active)_settings
    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['alerting']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['alerting_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['per-message_auth']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['user_level_auth']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']

    Valid Value  access_mode_ipmi_conf_map['${channel_info_ipmi['volatile(active)_settings']['access_mode']}']
    ...  ['${channel_volatile_data_config['${CHANNEL_NUMBER}']['access_mode']}']

    # Verify Non-Volatile Settings
    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['alerting']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['alerting_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['per-message_auth']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['per_msg_auth_disabled']}']

    Valid Value  disabled_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['user_level_auth']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['user_auth_disabled']}']

    Valid Value  access_mode_ipmi_conf_map['${channel_info_ipmi['non-volatile_settings']['access_mode']}']
    ...  ['${channel_nv_data_config['${CHANNEL_NUMBER}']['access_mode']}']


Test Get Channel Authentication Capabilities via IPMI
    [Documentation]  Test get channel authentication capabilities via IPMI.
    [Tags]  Test_Get_Channel_Authentication_Capabilities_via_IPMI

    ${channel_auth_cap}=  Get Channel Auth Capabilities  ${CHANNEL_NUMBER}
    Rprint Vars  channel_auth_cap

    Valid Value  channel_auth_cap['channel_number']  ['${CHANNEL_NUMBER}']
    Valid Value  channel_auth_cap['kg_status']  ['default (all zeroes)']
    Valid Value  channel_auth_cap['per_message_authentication']  ['enabled']
    Valid Value  channel_auth_cap['user_level_authentication']  ['enabled']
    Valid Value  channel_auth_cap['non-null_user_names_exist']  ['yes']
    Valid Value  channel_auth_cap['null_user_names_exist']  ['no']
    Valid Value  channel_auth_cap['anonymous_login_enabled']  ['no']
    Valid Value  channel_auth_cap['channel_supports_ipmi_v1.5']  ['no']
    Valid Value  channel_auth_cap['channel_supports_ipmi_v2.0']  ['yes']


Test Set Session Privilege Level via IPMI Raw Command
    [Documentation]  Set session privilegelLevel command via IPMI Raw Command.
    [Tags]  Test_Set_Session_Privilege_Level_via_IPMI_Raw_Command
    [Template]  Set Session Privilege Level

    # privilege_level   expected_level
    0x00                04
    0x02                02
    0x03                03
    0x04                04


*** Keywords ***

Set Session Privilege Level
    [Documentation]   Verify Set Seesion Privilege command with given privilege level and expected level.
    [Arguments]  ${privilege_level}  ${expected_level}
    # Description of argument(s):
    # privilege_level    Requested to set session privilege level.
    # expected_level     New Privilege Level (or present level if ‘return present privilege level’ was selected)

    ${resp}=  Run IPMI Standard Command
    ...  raw 0x06 0x3b ${privilege_level}
    Should Contain  ${resp}  ${expected_level}
