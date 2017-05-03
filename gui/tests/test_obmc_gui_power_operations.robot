*** Settings ***

Documentation  Test OBMC GUI Power Operations

Resource  ../lib/obmcgui_utils.robot

Suite Setup  OpenBMC GUI Login
Suite Teardown  Close Browser

*** Test Cases ***

Power On the CEC
    [Documentation]  Power on the CEC.
    [Tags]  Power_On_the_CEC

    GUI Power On

Warm Boot the CEC
    [Documentation]  Warm boot the CEC.
    [Tags]  Warm_Boot_the_CEC

    Controller Server Power Click  ${obmc_warm_boot}
    Controller Power Operations Confirmation Click  ${power_operations}
    ...  ${warm_boot}  ${confirm_msg}  ${yes}

Immediate Power Off the CEC
    [Documentation]  Immediate power off the CEC.
    [Tags]  Immediate_Power_Off_the_CEC

    Controller Server Power Click  ${obmc_immediate_shutdown}
    Controller Power Operations Confirmation Click  ${power_operations}
    ...  ${power_off}  ${confirm_msg}  ${yes}

Cold Boot the CEC
    [Documentation]  Cold boot the CEC.
    [Tags]  Cold_Boot_the_CEC

    Controller Server Power Click  ${obmc_cold_boot}
    Controller Power Operations Confirmation Click  ${power_operations}
    ...  ${cold_boot}  ${confirm_msg}  ${yes}

Orderly Shutdown the CEC
    [Documentation]  Orderly shutdown  the CEC.
    [Tags]  Orderly_Shutdown_the_CEC

    Controller Server Power Click  ${obmc_orderly_shutdown}
    Controller Power Operations Confirmation Click  ${power_operations}
    ...  ${shut_down}  ${confirm_msg}  ${yes}

OpenBMC GUI Logoff
    [Documentation]  Log out from OpenBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${obmc_BMC_URL}
    Log To Console  ${obmc_BMC_URL}
    Click Element  ${obmc_logout}




