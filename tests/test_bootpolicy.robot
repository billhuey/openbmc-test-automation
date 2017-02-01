*** Settings ***

Documentation   This testsuite is for testing boot policy function.

Resource           ../lib/rest_client.robot
Resource           ../lib/ipmi_client.robot
Resource           ../lib/utils.robot
Resource           ../lib/openbmc_ffdc.robot

Suite Setup        Open Connection And Log In
Test Setup         Initialize DBUS cmd   "boot_policy"
Test Teardown      FFDC On Test Case Fail
Suite Teardown     Restore Boot Settings

*** Variables ***
${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

Set Boot Policy To ONETIME via REST
    [Documentation]   Set boot policy to ONETIME using REST URI and verify
    ...               using ipmitool.
    [Tags]  Set_Boot_Policy_To_ONETIME_via_REST

    Set Boot Policy   ONETIME

    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Should Contain   ${output}    ONETIME

Set Boot Policy To PERMANENT via REST
    [Documentation]   Set boot policy to PERMANENT via REST URI and verify
    ...               using ipmitool.
    [Tags]  Set_Boot_Policy_To_PERMANENT_via_REST

    Set Boot Policy   PERMANENT

    ${boot}=   Read Attribute  ${HOST_SETTINGS}  boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Should Contain   ${output}     PERMANENT

Set Boot Policy To ONETIME via IPMITOOL
    [Documentation]   Set boot policy to ONETIME via ipmitool and verify
    ...               using REST URI.
    [Tags]  Set_Boot_Policy_To_ONETIME_via_IPMITOOL

    Run IPMI command  0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Should Contain   ${output}    ONETIME

Set Boot Policy To PERMANENT via IPMITOOL
    [Documentation]   Set boot policy to PERMANENT via ipmitool and verify
    ...               using REST URI.
    [Tags]  Set_Boot_Policy_To_PERMANENT_via_IPMITOOL

    Run IPMI command   0x0 0x8 0x05 0xC0 0x00 0x00 0x00 0x00
    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Should Contain   ${output}     PERMANENT

Test Boot Order via REST
    [Documentation]   Set boot policy to PERMANENT and boot device to CDROM
    ...               and verify that the order doesn't change post power on.
    [Tags]  chassisboot  Test_Boot_Order_via_REST

    Initiate Power Off

    Set Boot Policy   PERMANENT

    Set Boot Device   CDROM

    Initiate Power On

    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    PERMANENT

    ${flag}=   Read Attribute  ${HOST_SETTINGS}   boot_flags
    Should Be Equal    ${flag}    CDROM

Persist ONETIME Boot Policy After Reset
    [Documentation]   Verify ONETIME boot policy order does not change
    ...               on warm reset.
    [Tags]  chassisboot   Persist_ONETIME_Boot_Policy_After_Reset

    Initiate Power On

    Set Boot Policy   ONETIME

    Set Boot Device   Network

    Trigger Warm Reset

    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    ONETIME

    ${flag}=   Read Attribute  ${HOST_SETTINGS}  boot_flags
    Should Be Equal    ${flag}    Network

Persist PERMANENT Boot Policy After Reset
    [Documentation]   Verify PERMANENT boot policy order does not change
    ...               on warm reset.
    [Tags]  chassisboot    Persist_PERMANENT_Boot_Policy_After_Reset

    Initiate Power On

    Set Boot Policy   PERMANENT

    Set Boot Device   CDROM

    Trigger Warm Reset

    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Be Equal    ${boot}    PERMANENT

    ${flag}=   Read Attribute  ${HOST_SETTINGS}   boot_flags
    Should Be Equal    ${flag}    CDROM

Set Boot Policy To Invalid Value
    [Documentation]   This testcase verify that the boot policy doesn't get
    ...               updated with invalid policy supplied by user.
    [Tags]  Set_Boot_Policy_To_Invalid_Value

    Run Keyword and Ignore Error    Set Boot Policy   abc

    ${boot}=   Read Attribute  ${HOST_SETTINGS}   boot_policy
    Should Not Be Equal    ${boot}    abc

*** Keywords ***

Set Boot Policy
    [Arguments]    ${args}
    ${bootpolicy}=   Set Variable   ${args}
    ${valueDict}=   create dictionary   data=${bootpolicy}
    Write Attribute    ${HOST_SETTINGS}  boot_policy   data=${valueDict}

Set Boot Device
    [Arguments]    ${args}
    ${bootDevice} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    ${HOST_SETTINGS}   boot_flags   data=${valueDict}

Restore Boot Settings
    [Documentation]  Restore default settings.
    Set Boot Policy  ONETIME
    Set Boot Device  default
    Close All Connections
