*** Settings ***

Documentation    Module to test IPMI SEL functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${sensor_number}      0x17


*** Test Cases ***

Verify IPMI SEL Version
    [Documentation]  Verify IPMI SEL's version info.
    [Tags]  Verify_IPMI_SEL_Version
    ${version_info}=  Get IPMI SEL Setting  Version
    ${setting_status}=  Fetch From Left  ${version_info}  (
    ${setting_status}=  Evaluate  $setting_status.replace(' ','')

    Should Be True  ${setting_status} >= 1.5
    Should Contain  ${version_info}  v2 compliant  case_insensitive=True


Verify Empty SEL
    [Documentation]  Verify IPMI sel clear clears the SEL(s).
    [Tags]  Verify_Empty_SEL

    # Generate an error log and verify there is one atleast.
    Create Test PEL Log
    ${resp}=  Run IPMI Standard Command  sel elist last 1
    Log To Console  ${resp}

    Should Contain Any  ${resp}  system hardware failure   Asserted
    ...  msg=Add SEL Entry failed.

    # Send SEL clear command and verify if it really clears up the SEL entry.
    Run IPMI Standard Command  sel clear
    Sleep  5s

    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify Add SEL Entry
    [Documentation]  Verify add SEL entry.
    [Tags]  Verify_Add_SEL_Entry
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Run IPMI Standard Command  sel clear

    Run IPMI Standard Command  sel clear
    Sleep  5s

    # The IPMI raw command to generate Temp sensor  error is no longer working.
    # Our aim is to check if the SEL command is listed in IPMI or not.
    # Original keyword "Create SEL" for reference
    Create Test PEL Log

    # Get last SEL entry.
    ${resp}=  Run IPMI Standard Command  sel elist last 1
    #  output:
    #  1 | 11/17/2021 | 07:49:20 | System Event #0x01 | Undetermined system hardware failure | Asserted
    Run Keywords  Should Contain  ${resp}  system hardware failure  AND
    ...  Should Contain  ${resp}  Asserted  msg=Add SEL Entry failed.


Verify Reserve SEL
    [Documentation]  Verify reserve SEL.
    [Tags]  Verify_Reserve_SEL

    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Execute clear SEL raw command with Reservation ID.
    # Command will not execute unless the correct Reservation ID value is provided.
    Run IPMI Standard Command
    ...  raw 0x0a 0x47 0x${reserve_id[0]} 0x${reserve_id[1]} 0x43 0x4c 0x52 0xaa


*** Keywords ***

Create SEL
    [Documentation]  Create a SEL.

    # Create a SEL.
    # Example:
    # a | 02/14/2020 | 01:16:58 | Temperature #0x17 |  | Asserted
    Run IPMI Command
    ...  0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x01 ${sensor_number} 0x00 0xa0 0x04 0x07
