*** Settings ***
Documentation       Test RAS sanity scenarios using ecmd commands.

Resource            ../../lib/openbmc_ffdc.robot
Variables           ../../lib/ras/variables.py

Suite Setup         Redfish Power On
Test Setup          Printn
Test Teardown       FFDC On Test Case Fail


*** Variables ***
# mention count to read system memory.
${count}    128


*** Test Cases ***
Test Ecmd Getscom
    [Documentation]    Do getscom operation through BMC.
    [Tags]    test_ecmd_getscom
    Ecmd    getscom pu.c 20028440 -all

Test Ecmd Getcfam
    [Documentation]    Do getcfam operation through BMC.
    [Tags]    test_ecmd_getcfam
    Ecmd    getcfam pu ${cfam_address} -all

Test Ecmd Getmemproc
    [Documentation]    Do getmemproc operation through BMC.
    [Tags]    test_ecmd_getmemproc
    Ecmd    getmemproc ${mem_address} ${count}
