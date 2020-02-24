*** Settings ***

Documentation    Module to test PLDM BIOS commands.

Library          Collections
Library          String
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail
Suite Teardown   PLDM BIOS Suite Cleanup

*** Test Cases ***

Verify GetDateTime

    [Documentation]  Verify host date & time.
    [Tags]  Verify_GetDateTime

    # Example output:
    # YYYY-MM-DD HH:MM:SS - 09-02-2020 16:51:23

    ${pldm_output}=  Pldmtool  bios GetDateTime
    @{date_time}=  Split String  ${pldm_output}  ${SPACE}
    @{time}=  Split String  ${date_time}[1]  :

    # verify date & time.
    ${current_date_time}=  Get Current Date  UTC  exclude_millis=True
    Should Contain  ${current_date_time}  ${date_time[0]}
    Should Contain  ${current_date_time}  ${time[0]}


Verify SetDateTime

    [Documentation]  Verify set date & time for the host.
    [Tags]  Verify_SetDateTime

    # Example output:
    # SetDateTime: SUCCESS

    ${current_date_time}=  Get Current Date  UTC  exclude_millis=True

    ${date}=  Add Time To Date  ${current_date_time}  400 days  exclude_millis=True
    ${upgrade_date}=  Evaluate  re.sub(r'-* *:*', "", '${date}')  modules=re

    ${time}=  Add Time To Date  ${current_date_time}  01:01:00  exclude_millis=True
    ${upgrade_time}=  Evaluate  re.sub(r'-* *:*', "", '${time}')  modules=re

    # Set date.
    ${cmd_set_date}=  Evaluate  $CMD_SETDATETIME % '${upgrade_date}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date}
    Valid Value  pldm_output['setdatetime']  ['SUCCESS']

    # Set time.
    ${cmd_set_time}=  Evaluate  $CMD_SETDATETIME % '${upgrade_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_time}
    Valid Value  pldm_output['setdatetime']  ['SUCCESS']


Verify GetBIOSTable For StringTable
    [Documentation]  Verify GetBIOSTable for table type string table.
    [Tags]           Verify_GetBIOSTable_For_StringTable

    #pldm_output:
    #[biosstringhandle]:                             BIOSString
    #[0]:                                            Allowed
    #[1]:                                            Disabled
    #[2]:                                            Enabled
    #[3]:                                            Not Allowed
    #[4]:                                            Perm
    #[5]:                                            Temp
    #[6]:                                            pvm-fw-boot-side
    #[7]:                                            pvm-inband-code-update
    #[8]:                                            pvm-os-boot-side
    #[9]:                                            pvm-pcie-error-inject
    #[10]:                                           pvm-surveillance
    #[11]:                                           pvm-system-name
    #[12]:                                           vmi-if-count
 
    ${pldm_cmd}=  Evaluate  $CMD_GETBIOSTABLE % '0'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Rprint Vars  pldm_output
    Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETBIOSTABLE_STRTABLE}

*** Keywords ***

PLDM BIOS Suite Cleanup

    [Documentation]  Perform pldm BIOS suite cleanup.

    ${result}=  Get Current Date  UTC  exclude_millis=True
    ${current_date_time}=  Evaluate  re.sub(r'-* *:*', "", '${result}')  modules=re
    ${cmd_set_date_time}=  Evaluate  $CMD_SETDATETIME % '${current_date_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date_time}
    Valid Value  pldm_output['setdatetime']  ['SUCCESS']
