*** Settings ***
Documentation     Utilities for power management tests.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot
Library           ../lib/var_funcs.py


*** Keywords ***

DCMI Power Get Limits
    [Documentation]  Run dcmi power get_limit and put the returned values
    ...  into a dictionary for easy parsing.

    # This is keyword packages the five lines returned by dcmi power get_limit
    # command into a dictionary.  For example, the dcmi command may return:
    #  Current Limit State: No Active Power Limit
    #  Exception actions:   Hard Power Off & Log Event to SEL
    #  Power Limit:         500   Watts
    #  Correction time:     0 milliseconds
    #  Sampling period:     0 seconds
    # The user can get the power limit (watts number) with the following code:
    # &{limits}=  DCMI Power Get Limits
    # ${power_limit}=  Get From Dictionary  ${limits}  power_limit

    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${output}=  Remove String  ${output}  Watts
    ${output}=  Remove String  ${output}  milliseconds
    ${output}=  Remove String  ${output}  seconds
    &{limits}=  Key Value Outbuf To Dict  ${output}
    [Return]  &{limits}


Get DCMI Power Limit
    [Documentation]  Return the system's current DCMI power_limit
    ...  watts setting.

    &{limits}=  DCMI Power Get Limits
    ${power_setting}=  Get From Dictionary  ${limits}  power_limit
    [Return]  ${power_setting}


Set DCMI Power Limit And Verify
    [Documentation]  Set system power limit via IPMI DCMI command.
    [Arguments]  ${power_limit}

    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${power_limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_limit}
    ...  msg=Faied setting dcmi power limit to ${power_limit} watts.


Activate DCMI Power And Verify
    [Documentation]  Activate DCMI power limiting.

    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    Should Contain  ${resp}  successfully activated
    ...  msg=Command failed: dcmi power activate.


Fail If DCMI Power Is Not Activated
    [Documentation]  Fail if DCMI power limiting is not activated.

    ${cmd}=  Catenate  dcmi power get_limit | grep State:
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  Power Limit Active  msg=DCMI power is not active.


Deactivate DCMI Power And Verify
    [Documentation]  Deactivate DCMI power power limiting.

    ${cmd}=  Catenate  dcmi power deactivate | grep deactivated
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  successfully deactivated
    ...  msg=Command failed: dcmi power deactivater.


Fail If DCMI Power Is Not Deactivated
    [Documentation]  Fail if DCMI power limiting is not deactivated.

    ${cmd}=  Catenate  dcmi power get_limit | grep State:
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  No Active Power Limit
    ...  msg=DCMI power is not deactivated.


OCC Tool Upload Setup
    [Documentation]  Upload occtoolp9 to /tmp on the OS.

    ${cmd}=  Catenate  cd /tmp ; wget --no-check-certificate -q
    ...  -Oocctoolp9 --content-disposition
    ...  https://github.com/open-power/occ/raw/master/src/tools/occtoolp9
    ...  ; chmod 777 occtoolp9
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
