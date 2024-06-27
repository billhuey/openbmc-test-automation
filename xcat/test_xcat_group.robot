*** Settings ***
Documentation       Module for testing BMC via XCAT.

Resource            ../lib/xcat/resource.robot
Resource            ../lib/xcat/xcat_utils.robot
Library             OperatingSystem
Library             String

Suite Setup         Validate XCAT Setup
Suite Teardown      Close All Connections


*** Variables ***
${poweron_flag}                 ON
${poweroff_flag}                OFF
${NUM_POWER_STATUS_CHECKS}      1000


*** Test Cases ***
Add BMC Nodes To XCAT
    [Documentation]    Connect and add BMC nodes.
    [Tags]    add_bmc_nodes_to_xcat

    # Add BMC nodes one by one and check whether it is successfully added.
    FOR    ${bmc}    IN    @{BMC_LIST}
        Add Nodes To XCAT    ${bmc}
        Validate Added Node    ${bmc}
    END

Power On Via XCAT And Validate
    [Documentation]    Power on via XCAT and validate.
    [Tags]    power_on_via_xcat_and_validate

    # Power on each BMC node and validate the power status.
    FOR    ${bmc}    IN    @{BMC_LIST}
        Power On Via XCAT    ${bmc}
        Validate Power Status Via XCAT    ${bmc}    ${poweron_flag}
    END

Power Off Via XCAT And Validate
    [Documentation]    Power off via XCAT and validate.
    [Tags]    power_off_via_xcat_and_validate

    # Power off each BMC node and validate the power status.
    FOR    ${bmc}    IN    @{BMC_LIST}
        Power Off Via XCAT    ${bmc}
        Validate Power Status Via XCAT    ${bmc}    ${poweroff_flag}
    END

Add Nodes To Group List
    [Documentation]    Add BMC nodes into group.
    [Tags]    add_nodes_to_group_list

    # Add BMC nodes to group and validate.
    FOR    ${bmc}    IN    @{BMC_LIST}
        Add Nodes To Group    ${bmc}    ${GROUP}
        Validate Node Added In Group    ${bmc}    ${GROUP}
    END

Power On Group And Validate
    [Documentation]    Power on all BMCs in group and validate.
    [Tags]    power_on_group_and_validate

    # Sample output of this keyword:
    # XXX.XXX.XXX.XXX
    # YYY.YYY.YYY.YYY
    # ZZZ.ZZZ.ZZZ.ZZZ

    ${nodes}=    Get List Of Nodes In Group    ${GROUP}
    Should Not Be Empty    ${nodes}    msg=Group is empty.
    Power On Via XCAT    ${GROUP}

    # List the BMC nodes.

    @{bmc_nodes}=    Split String    ${nodes}

    # Validate power status on each BMC node one by one.
    FOR    ${bmc_node}    IN    @{bmc_nodes}
        Validate Power Status Via XCAT    ${bmc_node}    ${poweron_flag}
    END

Power Off Group And Validate
    [Documentation]    Power off all BMCs in group and validate.
    [Tags]    power_off_group_and_validate

    # Sample output of this keyword:
    # XXX.XXX.XXX.XXX
    # YYY.YYY.YYY.YYY
    # ZZZ.ZZZ.ZZZ.ZZZ

    ${nodes}=    Get List Of Nodes In Group    ${GROUP}
    Should Not Be Empty    ${nodes}    msg=Group is empty.
    Power Off Via XCAT    ${GROUP}

    # List the BMC nodes.
    @{bmc_nodes}=    Split String    ${nodes}

    # Validate power status on each BMC node one by one.
    FOR    ${bmc_node}    IN    @{bmc_nodes}
        Validate Power Status Via XCAT    ${bmc_node}    ${poweroff_flag}
    END

Continuous Node Power Status
    [Documentation]    Continuously get the power status.
    # This keyword verifies the REST connectivity between XCAT and the BMC node.
    [Tags]    continuous_node_power_status

    # Performing this operation only on one BMC node.

    Power On Via XCAT    ${BMC_LIST[1]}

    # Get the power status of the node repeatedly.
    # By default it gets power status 1000 times.
    # It basically stress the BMC node and test REST implementation
    # of the BMC node

    FOR    ${index}    IN RANGE    1    ${NUM_POWER_STATUS_CHECKS}
        Validate Power Status Via XCAT    ${BMC_LIST[1]}    ${poweron_flag}
    END

Get Temperature Reading Via XCAT
    [Documentation]    Get temperature reading via XCAT.
    [Tags]    get_temperature_reading_via_xcat

    # Sample output of the keyword:
    # node1: Ambient: 28.62 C
    # node1: P0 Vcs Temp: 35 C
    # node1: P0 Vdd Temp: 35 C
    # node1: P0 Vddr Temp: 35 C
    # node1: P0 Vdn Temp: 35 C
    # node1: P1 Vcs Temp: 33 C
    # node1: P1 Vdd Temp: 33 C
    # node1: P1 Vddr Temp: 34 C
    # node1: P1 Vdn Temp: 34 C

    # Get temperature reading from each BMC node.

    FOR    ${bmc}    IN    @{BMC_LIST}
        ${temp_reading}=    Get Hardware Vitals Via XCAT    ${bmc}    temp
        Should Match    ${temp_reading}    ${bmc}* C
        Log    \n Temperature reading on $[bmc}\n ${temp_reading}
    END

Get Fanspeed Reading Via XCAT
    [Documentation]    Get fanspeed via XCAT.
    [Tags]    get_fanspeed_reading_via_xcat

    # Sample output of the keyword:
    # node1: Fan0 0: 10714 RPMS
    # node1: Fan1 0: 10216 RPMS
    # node1: Fan2 0: 14124 RPMS
    # node1: Fan3 0: 11114 RPMS

    # Get fanspeed from each BMC node.

    FOR    ${bmc}    IN    @{BMC_LIST}
        ${fanspeed}=    Get Hardware Vitals Via XCAT    ${bmc}    fanspeed
        Should Match    ${fanspeed}    ${bmc}* RPMS
        Log    \n fanspeed on $[bmc}\n ${fanspeed}
    END

Get Voltage Reading Via XCAT
    [Documentation]    Get voltage via XCAT.
    [Tags]    get_voltage_reading_via_xcat

    # Sample output of the keyword:
    # node1: No attributes returned from the BMC.
    # BMC node is not returning anything, this will fail at present.

    # Get voltage reading from each BMC node.

    FOR    ${bmc}    IN    @{BMC_LIST}
        ${voltage}=    Get Hardware Vitals Via XCAT    ${bmc}    voltage
        Log    \n Voltage reading on $[bmc}\n ${voltage}
    END

Get Wattage Via XCAT
    [Documentation]    Get wattage via XCAT.
    [Tags]    get_wattage_via_xcat

    # Sample output of the keyword:
    # node1: No attributes returned from the BMC.
    # BMC node is not returning anything, this will fail at present.

    # Get wattage reading from each BMC node.

    FOR    ${bmc}    IN    @{BMC_LIST}
        ${wattage}=    Get Hardware Vitals Via XCAT    ${bmc}    wattage
        Log    \n Wattage reading on $[bmc}\n ${wattage}
    END


*** Keywords ***
Validate XCAT Setup
    [Documentation]    Validate XCAT setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=    Execute Command    ${XCAT_DIR_PATH}/lsxcatd -v
    Should Not Be Empty    ${cmd_output}    msg=XCAT not installed.

    Log    \n XCAT Version is: \n${cmd_output}

    # Get all the BMC nodes from the config file.
    ${nodes}=    Get List Of BMC Nodes
    # Make a list of BMC nodes.
    @{BMC_LIST}=    Split To Lines    ${nodes}
    Log To Console    BMC nodes to be added:\n ${BMC_LIST}
    Set Suite Variable    @{BMC_LIST}

    # GROUP should not be empty.
    Should Not Be EMPTY    ${GROUP}    msg=Group does not exist.

Validate Power Status Via XCAT
    [Documentation]    Validate power status.
    [Arguments]    ${node}    ${flag}=ON

    ${status}=    Get Power Status    ${node}
    IF    '${flag}' == 'ON'
        Should Contain    ${status}    on    msg=Host is off.
    ELSE
        Should Contain    ${status}    off    msg=Host is on.
    END
