*** Settings ***
Documentation       Utility for RAS test scenarios through HOST & BMC.
Resource            ../../lib/utils.robot
Resource            ../../lib/ras/host_utils.robot
Resource            ../../lib/resource.robot
Resource            ../../lib/state_manager.robot
Resource            ../../lib/boot_utils.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py
Resource            ../../lib/dump_utils.robot

Library             DateTime
Library             OperatingSystem
Library             random
Library             Collections

*** Variables ***
${stack_mode}       normal

*** Keywords ***

Verify And Clear Gard Records On HOST
    [Documentation]  Verify And Clear gard records on HOST.

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  No GARD
    Gard Operations On OS  clear all

Verify Error Log Entry
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # signature_desc  Error log signature description.
    # log_prefix      Log path prefix.


    Error Logs Should Exist

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output}=  Run and Return RC and Output
    ...  grep -i ${signature_desc} ${error_log_file_path}
    Should Be Equal  ${rc}  ${0}
    Should Not Be Empty  ${output}

Inject Recoverable Error With Threshold Limit
    [Documentation]  Inject and verify recoverable error on processor through
    ...              BMC/HOST.
    ...              Test sequence:
    ...              1. Inject recoverable error on a given target
    ...                 (e.g: Processor core, CAPP, MCA) through BMC/HOST.
    ...              2. Check If HOST is running.
    ...              3. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${interface_type}  ${fir_address}  ${value}  ${threshold_limit}
    ...              ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # interface_type      Inject error through 'BMC' or 'HOST'.
    # fir_address         FIR (Fault isolation register) value (e.g. 2011400).
    # value               (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).
    # signature_desc      Error log signature description.
    # log_prefix          Log path prefix.

    Run Keyword  Inject Error Through ${interface_type}
    ...  ${fir_address}  ${value}  ${threshold_limit}  ${master_proc_chip}

    Is Host Running
    ${output}=  Gard Operations On OS  list
    Should Contain  ${output}  No GARD
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}


Inject Unrecoverable Error
    [Documentation]  Inject and verify unrecoverable error on processor through
    ...              BMC/HOST.
    ...              Test sequence:
    ...              1. Inject unrecoverable error on a given target
    ...                 (e.g: Processor core, CAPP, MCA) through BMC/HOST.
    ...              2. Check If HOST is rebooted.
    ...              3. Verify & clear gard records.
    ...              4. Verify error log entry & signature description.
    ...              5. Verify & clear dump entry.
    [Arguments]      ${interface_type}  ${fir_address}  ${value}  ${threshold_limit}
    ...              ${signature_desc}  ${log_prefix}  ${bmc_reboot}=${0}
    # Description of argument(s):
    # interface_type      Inject error through 'BMC' or 'HOST'.
    # fir_address         FIR (Fault isolation register) value (e.g. 2011400).
    # value               (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).
    # signature_desc      Error Log signature description.
    #                     (e.g 'mcs(n0p0c0) (MCFIR[0]) mc internal recoverable')
    # log_prefix          Log path prefix.
    # bmc_reboot          Do bmc reboot If bmc_reboot is set.

    Run Keyword  Inject Error Through ${interface_type}
    ...  ${fir_address}  ${value}  ${threshold_limit}  ${master_proc_chip}

    # Do BMC Reboot after error injection.
    Run Keyword If  ${bmc_reboot}  Run Keywords
    ...    Initiate BMC Reboot
    ...    Wait For BMC Ready
    ...    Initiate Host PowerOff
    ...    Initiate Host Boot
    ...  ELSE
    ...    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted

    Wait for OS
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}

    ${dump_service_status}  ${stderr}  ${rc}=  BMC Execute Command  systemctl status xyz.openbmc_project.Dump.Manager.service
    Should Contain  ${dump_service_status}  Active: active (running)

    ${resp}=  OpenBMC Get Request  ${DUMP_URI}
    Run Keyword If  '${resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  Set Test Variable  ${DUMP_ENTRY_URI}  /xyz/openbmc_project/dump/entry/

    Read Properties  ${DUMP_ENTRY_URI}list
    Delete All BMC Dump
    Verify And Clear Gard Records On HOST


Fetch FIR Address Translation Value
    [Documentation]  Fetch FIR address translation value through HOST.
    [Arguments]  ${fir_address}  ${target_type}
    # Description of argument(s):
    # fir_address          FIR (Fault isolation register) value (e.g. '2011400').
    # core_id              Core ID (e.g. '9').
    # target_type          Target type (e.g. 'EX', 'EQ', 'C').

    Login To OS Host
    Copy Address Translation Utils To HOST OS

    # Fetch processor chip IDs.
    ${proc_chip_id}=  Get ProcChipId From OS  Processor  ${master_proc_chip}
    # Example output:
    # 00000000

    ${core_ids}=  Get Core IDs From OS  ${proc_chip_id[-1]}
    # Example output:
    #./probe_cpus.sh | grep 'CHIP ID: 0' | cut -c21-22
    # ['14', '15', '16', '17']

    # Ignoring master core ID.
    ${output}=  Get Slice From List  ${core_ids}  1
    # Feth random non-master core ID.
    ${core_ids_sub_list}=   Evaluate  random.sample(${core_ids}, 1)  random
    ${core_id}=  Get From List  ${core_ids_sub_list}  0
    ${translated_fir_addr}=  FIR Address Translation Through HOST
    ...  ${fir_address}  ${core_id}  ${target_type}

    [Return]  ${translated_fir_addr}

RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    Smart Power Off

    # Boot to OS.
    REST Power On  quiet=${1}
    # Adding delay after host bring up.
    Sleep  60s

RAS Suite Setup
    [Documentation]  Create RAS log directory to store all RAS test logs.

    ${RAS_LOG_DIR_PATH}=  Catenate  ${EXECDIR}/RAS_logs/
    Set Suite Variable  ${RAS_LOG_DIR_PATH}
    Set Suite Variable  ${master_proc_chip}  False

    Create Directory  ${RAS_LOG_DIR_PATH}
    OperatingSystem.Directory Should Exist  ${RAS_LOG_DIR_PATH}
    Empty Directory  ${RAS_LOG_DIR_PATH}

    Should Not Be Empty  ${ESEL_BIN_PATH}
    Set Environment Variable  PATH  %{PATH}:${ESEL_BIN_PATH}

    # Boot to Os.
    REST Power On  quiet=${1}

    # Check Opal-PRD service enabled on host.
    ${opal_prd_state}=  Is Opal-PRD Service Enabled
    Run Keyword If  '${opal_prd_state}' == 'disabled'
    ...  Enable Opal-PRD Service On HOST

RAS Suite Cleanup
    [Documentation]  Perform RAS suite cleanup and verify that host
    ...              boots after test suite run.

    # Boot to OS.
    REST Power On
    Delete Error Logs
    Gard Operations On OS  clear all


Inject Error At HOST Boot Path

    [Documentation]  Inject and verify recoverable error on processor through
    ...              BMC using pdbg tool at HOST Boot path.
    ...              Test sequence:
    ...              1. Inject error on a given target
    ...                 (e.g: Processor core, CAPP, MCA) through BMC using
    ...                 pdbg tool at HOST Boot path.
    ...              2. Check If HOST is rebooted and running.
    ...              3. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${fir_address}  ${value}  ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # fir_address         FIR (Fault isolation register) value (e.g. 2011400).
    # value               (e.g 2000000000000000).
    # signature_desc      Error log signature description.
    # log_prefix          Log path prefix.

    Inject Error Through BMC At HOST Boot  ${fir_address}  ${value}

    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted
    Wait for OS
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}
    Verify And Clear Gard Records On HOST
