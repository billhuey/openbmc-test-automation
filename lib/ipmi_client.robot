*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool IPMI standard
...             command. IPMI raw command will use dbus-send command
Resource        ../lib/resource.txt
Resource        ../lib/connection_client.robot
Resource        ../lib/utils.robot
Resource        ../lib/state_manager.robot

Library         String

*** Variables ***
${dbusHostIpmicmd1}=   dbus-send --system  ${OPENBMC_BASE_URI}HostIpmi/1
${dbusHostIpmiCmdReceivedMsg}=   ${OPENBMC_BASE_DBUS}.HostIpmi.ReceivedMessage
${netfnByte}=          ${EMPTY}
${cmdByte}=            ${EMPTY}
${arrayByte}=          array:byte:
${IPMI_EXT_CMD}=       ipmitool -I lanplus -C 3
${IPMI_USER_OPTIONS}   ${EMPTY}
${IPMI_INBAND_CMD}=    ipmitool -C 3
${HOST}=               -H
${RAW}=                raw

*** Keywords ***

Run IPMI Command
    [Arguments]  ${args}
    ${resp}=  Run Keyword If  '${IPMI_COMMAND}' == 'External'
    ...  Run External IPMI RAW Command  ${args}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Inband'
    ...  Run Inband IPMI RAW Command  ${args}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Dbus'
    ...  Run Dbus IPMI RAW Command  ${args}
    ...  ELSE  Fail  msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}
    [Return]  ${resp}

Run IPMI Standard Command
    [Arguments]  ${args}
    ${resp}=  Run Keyword If  '${IPMI_COMMAND}' == 'External'
    ...  Run External IPMI Standard Command  ${args}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Inband'
    ...  Run Inband IPMI Standard Command  ${args}
    ...  ELSE IF  '${IPMI_COMMAND}' == 'Dbus'
    ...  Run Dbus IPMI Standard Command  ${args}
    ...  ELSE  Fail  msg=Invalid IPMI Command type provided : ${IPMI_COMMAND}

    [Return]  ${resp}

Run Dbus IPMI RAW Command
    [Arguments]    ${args}
    ${valueinBytes}=   Byte Conversion  ${args}
    ${cmd}=   Catenate   ${dbushostipmicmd1} ${dbusHostIpmiCmdReceivedMsg}
    ${cmd}=   Catenate   ${cmd} ${valueinBytes}
    ${output}   ${stderr}=  Execute Command  ${cmd}  return_stderr=True
    Should Be Empty      ${stderr}
    set test variable    ${OUTPUT}     "${output}"

Run Dbus IPMI Standard Command
    [Arguments]    ${args}
    Copy ipmitool
    ${stdout}    ${stderr}    ${output}=  Execute Command
    ...    /tmp/ipmitool -I dbus ${args}    return_stdout=True
    ...    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [Return]    ${stdout}

Run Inband IPMI Raw Command
    [Documentation]  Run Inband IPMI raw command.
    [Arguments]  ${args}  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Desription of arguments:
    # ${args}  parameters to IPMI command.
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    Login To OS Host  ${os_host}  ${os_username}  ${os_password}
    Check If IPMI Tool Exist

    ${inband_raw_cmd}=  Catenate  ${IPMI_INBAND_CMD}  ${RAW}  ${args}
    ${stdout}  ${stderr}=  Execute Command  ${inband_raw_cmd}  return_stderr=True
    Should Be Empty  ${stderr}  msg=${stdout}
    [Return]  ${stdout}

Run Inband IPMI Standard Command
    [Documentation]  Run Inband IPMI standard command.
    [Arguments]  ${args}  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Desription of arguments:
    # ${args}  parameters to IPMI command.
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    Login To OS Host  ${os_host}  ${os_username}  ${os_password}
    Check If IPMI Tool Exist

    ${inband_std_cmd}=  Catenate  ${IPMI_INBAND_CMD}  ${args}
    ${stdout}  ${stderr}=  Execute Command  ${inband_std_cmd}  return_stderr=True
    Should Be Empty  ${stderr}  msg=${stdout}
    [Return]  ${stdout}

Run External IPMI RAW Command
    [Arguments]    ${args}
    ${ipmi_raw_cmd}=   Catenate  SEPARATOR=
    ...    ${IPMI_EXT_CMD} -P${SPACE}${IPMI_PASSWORD}${SPACE}
    ...    ${HOST}${SPACE}${OPENBMC_HOST}${SPACE}${RAW}${SPACE}${args}
    ${rc}    ${output}=    Run and Return RC and Output    ${ipmi_raw_cmd}
    Should Be Equal    ${rc}    ${0}    msg=${output}
    [Return]    ${output}

Run External IPMI Standard Command
    [Arguments]    ${args}

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ${IPMI_EXT_CMD} ${IPMI_USER_OPTIONS} -P${SPACE}${IPMI_PASSWORD}
    ...  ${SPACE}${HOST}${SPACE}${OPENBMC_HOST}${SPACE}${args}
    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd}
    Should Be Equal  ${rc}  ${0}  msg=${output}
    [Return]  ${output}

Check If IPMI Tool Exist
    [Documentation]  Check if IPMI Tool installed or not.
    ${output}=  Execute Command  which ipmitool
    Should Not Be Empty  ${output}  msg=ipmitool not installed.


Activate SOL Via IPMI
    [Documentation]  Start SOL using IPMI and route output to a file.
    [Arguments]  ${file_path}=/tmp/sol_${OPENBMC_HOST}
    # Description of argument(s):
    # file_path  The file path on the local machine (vs OBMC) to collect SOL
    #            output. By default SOL output is collected at
    #            /tmp/sol_<BMC_IP> else user input location.

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ${IPMI_EXT_CMD} -P${SPACE}${IPMI_PASSWORD}${SPACE}
    ...  ${HOST}${SPACE}${OPENBMC_HOST}${SPACE}sol activate

    Run Process  ${ipmi_cmd}  shell=True  stdout=${file_path}
    ...  timeout=5s  on_timeout=continue


Deactivate SOL Via IPMI
    [Documentation]  Stop SOL using IPMI and return SOL output.
    [Arguments]  ${file_path}=/tmp/sol_${OPENBMC_HOST}
    # Description of argument(s):
    # file_path  The file path on the local machine to copy SOL output
    #            collected by above "Activate SOL Via IPMI" keyword.
    #            By default it copies log from /tmp/sol_<BMC_IP>.

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ${IPMI_EXT_CMD} -P${SPACE}${IPMI_PASSWORD}${SPACE}
    ...  ${HOST}${SPACE}${OPENBMC_HOST}${SPACE}sol deactivate

    ${rc}  ${output}=  Run and Return RC and Output  ${ipmi_cmd}
    Run Keyword If  ${rc} > 0  Return From Keyword  ${output}

    ${rc}  ${output}=  Run and Return RC and Output  cat ${file_path}
    Should Be Equal  ${rc}  ${0}  msg=${output}

    # Logging SOL output for debug purpose.
    Log  ${output}

    [Return]  ${output}


Byte Conversion
    [Documentation]   Byte Conversion method receives IPMI RAW commands as
    ...               argument in string format.
    ...               Sample argument is as follows
    ...               "0x04 0x30 9 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00
    ...               0x00"
    ...               IPMI RAW command format is as follows
    ...               <netfn Byte> <cmd Byte> <Data Bytes..>
    ...               This method converts IPMI command format into
    ...               dbus command format  as follows
    ...               <byte:seq-id> <byte:netfn> <byte:lun> <byte:cmd>
    ...               <array:byte:data>
    ...               Sample dbus  Host IPMI Received Message argument
    ...               byte:0x00 byte:0x04 byte:0x00 byte:0x30
    ...               array:byte:9,0x01,0x00,0x35,0x00,0x00,0x00,0x00,0x00,0x00
    [Arguments]     ${args}
    ${argLength}=   Get Length  ${args}
    Set Global Variable  ${arrayByte}   array:byte:
    @{listargs}=   Split String  ${args}
    ${index}=   Set Variable   ${0}
    :FOR   ${word}   in   @{listargs}
    \    Run Keyword if   ${index} == 0   Set NetFn Byte  ${word}
    \    Run Keyword if   ${index} == 1   Set Cmd Byte    ${word}
    \    Run Keyword if   ${index} > 1    Set Array Byte  ${word}
    \    ${index}=    Set Variable    ${index + 1}
    ${length}=   Get Length  ${arrayByte}
    ${length}=   Evaluate  ${length} - 1
    ${arrayByteLocal}=  Get Substring  ${arrayByte}  0   ${length}
    Set Global Variable  ${arrayByte}   ${arrayByteLocal}
    ${valueinBytesWithArray}=   Catenate  byte:0x00   ${netfnByte}  byte:0x00
    ${valueinBytesWithArray}=   Catenate  ${valueinBytesWithArray}  ${cmdByte}
    ${valueinBytesWithArray}=   Catenate  ${valueinBytesWithArray} ${arrayByte}
    ${valueinBytesWithoutArray}=   Catenate  byte:0x00 ${netfnByte}  byte:0x00
    ${valueinBytesWithoutArray}=   Catenate  ${valueinBytesWithoutArray} ${cmdByte}
#   To Check scenario for smaller IPMI raw commands with only 2 arguments
#   instead of usual 12 arguments.
#   Sample small IPMI raw command: Run IPMI command 0x06 0x36
#   If IPMI raw argument length is only 9 then return value in bytes without
#   array population.
#   Equivalent dbus-send argument for smaller IPMI raw command:
#   byte:0x00 byte:0x06 byte:0x00 byte:0x36
    Run Keyword if   ${argLength} == 9     Return from Keyword    ${valueinBytesWithoutArray}
    [Return]    ${valueinBytesWithArray}


Set NetFn Byte
   [Arguments]    ${word}
   ${netfnByteLocal}=  Catenate   byte:${word}
   Set Global Variable  ${netfnByte}  ${netfnByteLocal}

Set Cmd Byte
   [Arguments]    ${word}
   ${cmdByteLocal}=  Catenate   byte:${word}
   Set Global Variable  ${cmdByte}  ${cmdByteLocal}

Set Array Byte
   [Arguments]    ${word}
   ${arrayByteLocal}=   Catenate   SEPARATOR=  ${arrayByte}  ${word}
   ${arrayByteLocal}=   Catenate   SEPARATOR=  ${arrayByteLocal}   ,
   Set Global Variable  ${arrayByte}   ${arrayByteLocal}

Copy ipmitool
    OperatingSystem.File Should Exist   tools/ipmitool      msg=The ipmitool program could not be found in the tools directory. It is not part of the automation code by default. You must manually copy or link the correct openbmc version of the tool in to the tools directory in order to run this test suite.

    Import Library      SCPLibrary      WITH NAME       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x /tmp/ipmitool
