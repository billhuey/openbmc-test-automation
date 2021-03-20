*** Settings ***
Documentation   Suite to test hardware sensors.

Resource        ../lib/utils.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/ipmi_client.robot
Variables       ../data/ipmi_raw_cmd_table.py

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

*** Test Cases ***


Verify System Ambient Temperature
    [Documentation]  Check the ambient sensor temperature.
    [Tags]  Verify_System_Ambient_Temperature

    # Example:
    # /xyz/openbmc_project/sensors/temperature/ambient
    # {
    #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
    #     "Value": 25.767
    # }

    ${temp_data}=  Read Properties  ${SENSORS_URI}temperature/ambient
    Should Be Equal As Strings
    ...  ${temp_data["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
    Should Be True  ${temp_data["Value"]} <= ${50}
    ...  msg=System working temperature crossed 50 degree celsius.


Verify Fan Sensors Attributes
   [Documentation]  Check fan attributes.
   [Tags]  Verify_Fan_Sensor_Attributes

   # Example:
   # "/xyz/openbmc_project/sensors/fan_tach/fan0_0",
   # "/xyz/openbmc_project/sensors/fan_tach/fan0_1",
   # "/xyz/openbmc_project/sensors/fan_tach/fan1_0",
   # "/xyz/openbmc_project/sensors/fan_tach/fan1_1",
   # "/xyz/openbmc_project/sensors/fan_tach/fan2_0",
   # "/xyz/openbmc_project/sensors/fan_tach/fan2_1",
   # "/xyz/openbmc_project/sensors/fan_tach/fan3_0",
   # "/xyz/openbmc_project/sensors/fan_tach/fan3_1"

   ${fans}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  fan*

   # Access the properties of the fan and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/fan_tach/fan0_0
   # {
   #     "Functional": true,
   #     "MaxValue": 0.0,
   #     "MinValue": 0.0,
   #     "Target": 10500,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.RPMS",
   #     "Value": 0.0
   # }

   FOR  ${entry}  IN  @{fans}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Run Keyword And Ignore Error  Should Be True  ${json["data"]["Target"]} >= 0
     Run Keyword And Ignore Error  Should Be Equal As Strings
     ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.RPMS
     Should Be True  ${json["data"]["Value"]} >= 0
   END

Verify PCIE Sensors Attributes
   [Documentation]  Probe PCIE attributes.
   [Tags]  Verify_PCIE_Sensor_Attributes
   # Example:
   # /xyz/openbmc_project/sensors/temperature/pcie
   ${temp_pcie}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  pcie

   # Access the properties of the PCIE and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/pcie
   # {
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #    "Value": 29.625
   # }


   FOR  ${entry}  IN  @{temp_pcie}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
     Should Be True  ${json["data"]["Value"]} > 0
   END


Verify Rail Voltage Sensors Attributes
   [Documentation]  Check rail voltage attributes.
   [Tags]  Verify_Rail_Voltage_Sensor_Attributes
   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/voltage/rail_1_voltage
   # /xyz/openbmc_project/sensors/voltage/rail_2_voltage
   ${temp_rail}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  rail*

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # "/xyz/openbmc_project/sensors/voltage/rail_1_voltage":
   # {
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Volts",
   #    "Value": 5.097
   # },

   FOR  ${entry}  IN  @{temp_rail}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.Volts
     Should Be True  ${json["data"]["Value"]} > 0
   END


Verify VDN Temperature Sensors Attributes
   [Documentation]  Check vdn temperature attributes.
   [Tags]  Verify_VDN_Temperature_Sensors_Attributes
   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vdn_temp
   ${temp_vdn}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vdn_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vdn_temp
   # {
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #    "Value": 3.000
   # }

   FOR  ${entry}  IN  @{temp_vdn}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
     Should Be True  ${json["data"]["Value"]} > 0
   END

Verify VCS Temperature Sensors Attributes
   [Documentation]  Check vcs temperature attributes.
   [Tags]  Verify_VCS_Temperature_Sensors_Attributes
   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vcs_temp
   ${temp_vcs}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vcs_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vcs_temp
   # {
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 31.000
   # },


   FOR  ${entry}  IN  @{temp_vcs}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
     Should Be True  ${json["data"]["Value"]} > 0
   END


Verify VDD Temperature Sensors Attributes
   [Documentation]  Check vdd temperature attributes.
   [Tags]  Verify_VDD_Temperature_Sensors_Attributes
   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vdd_temp
   ${temp_vdd}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vdd_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vdd_temp
   # {
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 4.000
   # }

   FOR  ${entry}  IN  @{temp_vdd}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
     Should Be True  ${json["data"]["Value"]} > 0
   END


Verify VDDR Temperature Sensors Attributes
   [Documentation]  Check vddr temperature attributes.
   [Tags]  Verify_VDDR_Temperature_Sensors_Attributes
   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vddr_temp
   ${temp_vddr}=
   ...  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vddr_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vddr_temp
   # {
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 4.000
   # }

   FOR  ${entry}  IN  @{temp_vddr}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Should Be Equal As Strings  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
     Should Be True  ${json["data"]["Value"]} > 0
   END

Verify Power Sensors Attributes
   [Documentation]  Check power sensor attributes.
   [Tags]  Verify_Power_Sensor_Attributes
   # Example:
   # /xyz/openbmc_project/sensors/power/power_1
   # /xyz/openbmc_project/sensors/power/power_2
   # /xyz/openbmc_project/sensors/power/power0
   # /xyz/openbmc_project/sensors/power/POWER1
   # /xyz/openbmc_project/sensors/power/POWER_1

   ${power}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  power*

   # Access the properties of the power sensors and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/power/power_1
   # {
   #     "MaxValue": 255.0,
   #     "MinValue": 0.0,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Watts",
   #     "Value": 0.0
   # }

   FOR  ${entry}  IN  @{power}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Run Keyword And Ignore Error  Should Be True  ${json["data"]["Target"]} >= 0
     Should Be True  ${json["data"]["Value"]} >= 0
   END


Verify Voltage Sensors Attributes
   [Documentation]  Check voltage sensors attributes.
   [Tags]  Verify_Voltage_Sensor_Attributes

   # Example:
   # "/xyz/openbmc_project/sensors/voltage/voltage0",
   # "/xyz/openbmc_project/sensors/voltage/voltage_1",
   # "/xyz/openbmc_project/sensors/voltage/VOLTAGE_2",
   # "/xyz/openbmc_project/sensors/voltage/VOLTAGE1",
   # "/xyz/openbmc_project/sensors/voltage/voltage".

   ${voltage}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/voltage/  *

   # Access the properties of the voltage sensors and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/voltage/voltage0
   # {
   #     "MaxValue": 255.0,
   #     "MinValue": 0.0,
   #     "Unit": xyz.openbmc_project.Sensor.Value.Unit.Volts
   #     "Value": 0.0
   # }

   FOR  ${entry}  IN  @{voltage}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Run Keyword And Ignore Error  Should Be Equal As Strings
     ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.Volts
     Run Keyword And Ignore Error  Should Be True  ${json["data"]["Value"]} >= 0
   END


Verify Current Sensors Attributes
   [Documentation]  Check current sensors attributes.
   [Tags]  Verify_Current_Sensor_Attributes

   # Example:
   # "/xyz/openbmc_project/sensors/current/current0",
   # "/xyz/openbmc_project/sensors/current/current_1",
   # "/xyz/openbmc_project/sensors/current/CURRENT_2",
   # "/xyz/openbmc_project/sensors/current/CURRENT1",
   # "/xyz/openbmc_project/sensors/current/current".

   ${current}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  curr*

   # Access the properties of the current sensors and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/current/current0
   # {
   #     "MaxValue": 255.0,
   #     "MinValue": 0.0,
   #     "Unit": xyz.openbmc_project.Sensor.Value.Unit.Amperes
   #     "Value": 0.0
   # }

   FOR  ${entry}  IN  @{current}
     ${resp}=  OpenBMC Get Request  ${entry}
     ${json}=  To JSON  ${resp.content}
     Run Keyword And Ignore Error  Should Be Equal As Strings
     ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.Amperes
     Should Be True  ${json["data"]["Value"]} >= 0
   END


Verify Power Redundancy Using REST
   [Documentation]  Verify power redundancy is enabled.
   [Tags]  Verify_Power_Redundancy_Using_REST

   # Example:
   # /xyz/openbmc_project/sensors/chassis/PowerSupplyRedundancy
   # {
   #     "error": 0,
   #     "units": "",
   #     "value": "Enabled"
   # }

   # Power Redundancy is a read-only attribute.  It cannot be set.

   # Pass if sensor is in /xyz and it's enabled.
   ${redundancy_setting}=  Read Attribute
   ...  ${OPENBMC_BASE_URI}control/power_supply_redundancy
   ...  PowerSupplyRedundancyEnabled
   Should Be Equal As Integers  ${redundancy_setting}  ${1}
   ...  msg=PowerSupplyRedundancyEnabled not set as expected.


Verify Power Redundancy Using IPMI
    [Documentation]  Verify IPMI reports Power Redundancy is enabled.
    [Tags]  Verify_Power_Redundancy_Using_IPMI

    # Refer to data/ipmi_raw_cmd_table.py for command definition.
    # Power Redundancy is a read-only attribute.  It cannot be set.

    ${output}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['power_supply_redundancy']['Get'][0]}

    ${scanning}=  Set Variable
    ...  ${IPMI_RAW_CMD['power_supply_redundancy']['Get'][5]}
    ${no_scanning}=  Set Variable
    ...  ${IPMI_RAW_CMD['power_supply_redundancy']['Get'][3]}

    ${enabled_scanning}=  Evaluate  $scanning in $output
    ${enabled_no_scanning}=  Evaluate  $no_scanning in $output

    # Either enabled_scanning or enabled_noscanning should be True.
    Should Be True  ${enabled_scanning} or ${enabled_no_scanning}
    ...  msg=Failed IPMI power redundancy check, result=${output}.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the initial test suite setup.
    # - Power off.
    # - Boot Host.
    REST Power Off  stack_mode=skip
    REST Power On

Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # - Capture FFDC on test failure.
    # - Delete error logs.
    # - Close all open SSH connections.

    FFDC On Test Case Fail
    Delete All Error Logs
    Close All Connections
