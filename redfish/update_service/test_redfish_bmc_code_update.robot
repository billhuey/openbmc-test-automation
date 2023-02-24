*** Settings ***
Documentation            Update firmware on a target BMC via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH        The path to the BMC image file.
#
# Firmware update states:
#     Enabled            Image is installed and either functional or active.
#     Disabled           Image installation failed or ready for activation.
#     Updating           Image installation currently in progress.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/common_utils.robot
Resource                 ../../lib/code_update_utils.robot
Resource                 ../../lib/dump_utils.robot
Resource                 ../../lib/logging_utils.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Resource                 ../../lib/utils.robot
Resource                 ../../lib/bmc_redfish_utils.robot
Resource                 ../../lib/external_intf/management_console_utils.robot
Resource                 ../../lib/bmc_network_utils.robot
Resource                 ../../lib/certificate_utils.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/tftp_update_utils.py
Library                  ../../lib/gen_robot_keyword.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Force Tags               BMC_Code_Update

*** Variables ***

@{ADMIN}          admin_user  TestPwd123
&{USERS}          Administrator=${ADMIN}
${LOOP_COUNT}     ${2}
@{HOSTNAME}       bmc_system01  bmc_system02  bmc_system03  bmc_system04  bmc_system05

*** Test Cases ***

Redfish Code Update With ApplyTime OnReset
    [Documentation]  Update the firmware image with ApplyTime of OnReset.
    [Tags]  Redfish_Code_Update_With_ApplyTime_OnReset
    [Template]  Redfish Update Firmware

    # policy
    OnReset


Redfish Code Update With ApplyTime Immediate
    [Documentation]  Update the firmware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_ApplyTime_Immediate
    [Template]  Redfish Update Firmware

    # policy
    Immediate


Redfish Code Update Same Firmware Multiple Times
    [Documentation]  Multiple times update the firmware image for update service.
    [Tags]  Redfish_Code_Update_Same_Firmware_Multiple_Times

    ${temp_update_loop_count}=  Evaluate  ${LOOP_COUNT} + 1

    FOR  ${count}  IN RANGE  1  ${temp_update_loop_count}
       Print Timen  ***************************************
       Print Timen  * The Current Loop Count is ${count} of ${LOOP_COUNT} *
       Print Timen  ***************************************

       Redfish Update Firmware  apply_time=OnReset
    END



Redfish Code Update With Multiple Firmware
    [Documentation]  Update the firmware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_Multiple_Firmware
    [Template]  Redfish Multiple Upload Image And Check Progress State

    # policy   image_file_path     alternate_image_file_path
    Immediate  ${IMAGE_FILE_PATH}  ${ALTERNATE_IMAGE_FILE_PATH}


Post BMC Reset Perform Redfish Code Update
    [Documentation]  Test to reset BMC at standby and then perform BMC firmware update and
    ...              ensure there is not error or dump logs post update.
    [Tags]  Post_BMC_Reset_Perform_Redfish_Code_Update

    Redfish Delete All BMC Dumps
    Redfish Purge Event Log

    Redfish OBMC Reboot (off)

    Redfish Update Firmware  apply_time=OnReset

    Event Log Should Not Exist
    Redfish BMC Dump Should Not Exist

    Redfish Power Off


Post BMC Reset Perform Image Switched To Backup Multiple Times
    [Documentation]  Test to reset BMC at standby and then perform switch
    ...              to backup image multiple times.
    ...              Then ensure no event and dump logs exist.
    [Tags]  Post_BMC_Reset_Perform_Image_Switched_To_Backup_Multiple_Times

    Redfish Delete All BMC Dumps
    Redfish Purge Event Log

    Redfish OBMC Reboot (off)

    ${temp_update_loop_count}=  Evaluate  ${LOOP_COUNT} + 1

    FOR  ${count}  IN RANGE  1  ${temp_update_loop_count}
      ${state}=  Get Pre Reboot State

      # change to backup image and reset the BMC.
      Switch Backup Firmware Image To Functional

      Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}
    END

    Event Log Should Not Exist
    Redfish BMC Dump Should Not Exist


Verify If The Modified Admin Credential Is Valid Post Image Switched To Backup
    [Documentation]  Verify updated admin credential remain same post switch to back up image.
    [Tags]  Verify_If_The_Modified_Admin_Credential_Is_Valid_Post_Image_Switched_To_Backup
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Teardown]  Run Keywords  Redfish.Login  AND  Delete BMC Users Via Redfish  users=${USERS}

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Expire And Update New Password Via Redfish  ${ADMIN[0]}  ${ADMIN[1]}  0penBmc123

    Redfish.Login
    # change to backup image and reset the BMC.
    Switch Backup Firmware Image To Functional
    Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}

    # verify modified admin password on backup image.
    Redfish.Login  admin_user  0penBmc123
    Redfish.Logout


Verify If The Modified Admin Credential Is Valid Post Update
    [Documentation]  Verify updated admin credential remain same post code update image.
    [Tags]  Verify_If_The_Modified_Admin_Credential_Is_Valid_Post_Update
    [Setup]  Create Users With Different Roles  users=${USERS}  force=${True}
    [Teardown]  Run Keywords  Redfish.Login  AND  Delete BMC Users Via Redfish  users=${USERS}

    Expire And Update New Password Via Redfish  ${ADMIN[0]}  ${ADMIN[1]}  0penBmc123

    Redfish.Login
    # Flash latest firmware using redfish.
    Redfish Update Firmware  OnReset

    # verify modified admin credentails on latest image.
    Redfish.Login  admin_user  0penBmc123
    Redfish.Logout


Redfish Code Update With Different Interrupted Operation
    [Documentation]  Ensure firmware update is successful when different interrupted operation executed
    ...              i.e. change the hostname.
    [Tags]  Redfish_Code_Update_With_Different_Interrupted_Operation
    [Template]  Verify Redfish Code Update With Different Interrupted Operation

    # operation          count
    #host_name            1
    #kernel_panic         1
    https_certificate    1

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Valid File Path  IMAGE_FILE_PATH
    Redfish.Login

    Redfish Delete All BMC Dumps
    Redfish Purge Event Log

    Redfish Power Off  stack_mode=skip


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Set ApplyTime  policy=${apply_Time}

    ${task_inv_dict}=  Get Task State from File

    ${file_bin_data}=  OperatingSystem.Get Binary File  ${image_file_path}

    Log To Console   Start uploading image to BMC.
    Upload Image To BMC  ${REDFISH_BASE_URI}UpdateService  timeout=${600}  data=${file_bin_data}
    Log To Console   Completed image upload to BMC.

    ${task_inv}=  Check Task With Match TargetUri  /redfish/v1/UpdateService

    Rprint Vars  task_inv

    Wait Until Keyword Succeeds  5 min  10 sec
    ...  Verify Task Progress State  ${task_inv}  ${task_inv_dict['TaskCompleted']}

    Run Key  ${post_code_update_actions['BMC image']['${apply_time}']}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}
    Verify Get ApplyTime  ${apply_time}


Redfish Multiple Upload Image And Check Progress State
    [Documentation]  Update multiple BMC firmware via redfish interface and check status.
    [Arguments]  ${apply_time}  ${IMAGE_FILE_PATH}  ${ALTERNATE_IMAGE_FILE_PATH}

    # Description of argument(s):
    # apply_time                 ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # IMAGE_FILE_PATH            The path to BMC image file.
    # ALTERNATE_IMAGE_FILE_PATH  The path to alternate BMC image file.

    ${post_code_update_actions}=  Get Post Boot Action
    Valid File Path  ALTERNATE_IMAGE_FILE_PATH
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${apply_time}
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}

    ${first_image_id}=  Get Latest Image ID
    Rprint Vars  first_image_id
    Sleep  5s
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${ALTERNATE_IMAGE_FILE_PATH}

    ${second_image_id}=  Get Latest Image ID
    Rprint Vars  second_image_id

    Check Image Update Progress State
    ...  match_state='Updating', 'Disabled'  image_id=${second_image_id}

    Check Image Update Progress State
    ...  match_state='Updating'  image_id=${first_image_id}

    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${first_image_id}
    Run Key  ${post_code_update_actions['BMC image']['${apply_time}']}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}


Run Configure BMC Hostname In Loop
    [Documentation]  Update hostname in loop.
    [Arguments]  ${count}

    # Description of argument(s):
    # count    Loop count.

    FOR  ${index}  IN RANGE  ${count}
      Configure Hostname  hostname=${HOSTNAME}[${index}]  status_code=[${HTTP_INTERNAL_SERVER_ERROR}]
    END


Redfish Update Certificate Upload In Loop
    [Documentation]
    [Arguments]  ${count}

    # Description of argument(s):
    # count    Loop count.

    FOR  ${index}  IN RANGE  ${count}

      ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
      ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
      ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

      ${certificate_dict}=  Create Dictionary
      ...  @odata.id=/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
      ${payload}=  Create Dictionary  CertificateString=${file_data}
      ...  CertificateType=PEM  CertificateUri=${certificate_dict}

      ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
      ...  body=${payload}

      #Verify Certificate Visible Via OpenSSL  ${cert_file_path}
    END


Run Operation On BMC
    [Documentation]  Run operation on BMC.
    [Arguments]  ${operation}  ${count}

    # Description of argument(s):
    # operation    If host_name then change hostname.
    # count        Loop count.

    Run Keyword If  '${operation}' == 'host_name'  Run Configure BMC Hostname In Loop  count=${count}
    Run Keyword If  '${operation}' == 'kernel_panic'
    ...  Run Keywords  Kernel Panic BMC Reset Operation  AND
    ...  Is BMC Unpingable
    Run Keyword If  '${operation}' == 'https_certificate'  Redfish Update Certificate Upload In Loop  count=${count}


Get Active Firmware Image
    [Documentation]  Return get active firmware image.

    ${active_image}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  Links
    Rprint Vars  active_image

    [Return]  ${active_image}


Get New Image ID
    [Documentation]  Return the ID of the most recently extracted image.

    ${image_id}=   Get Image Id   Updating

    [Return]  ${image_id}


Verify Redfish Code Update With Different Interrupted Operation
    [Documentation]  Verify code update is successful when other operation
    ...              getting executed i.e. change the hostname.
    [Arguments]  ${operation}  ${count}

    # Description of argument(s):
    # operation    host_name to change Hostname, kernel_panic to perform kernel panic.
    # count        Number of times loop will get executed.

    ${before_update_activeswimage}=  Get Active Firmware Image

    ${post_code_update_actions}=  Get Post Boot Action

    Set ApplyTime  policy=OnReset

    ${task_inv_dict}=  Get Task State from File

    ${file_bin_data}=  OperatingSystem.Get Binary File  ${image_file_path}

    Log To Console   Start uploading image to BMC.
    Upload Image To BMC  ${REDFISH_BASE_URI}UpdateService  timeout=${600}  data=${file_bin_data}
    Log To Console   Completed image upload to BMC.

    Sleep  5

    ${image_id}=  Get New Image ID
    Rprint Vars  image_id

    ${task_inv}=  Check Task With Match TargetUri  /redfish/v1/UpdateService
    Rprint Vars  task_inv

    Wait Until Keyword Succeeds  1 min  10 sec
    ...  Verify Task Progress State  ${task_inv}  ${task_inv_dict['TaskStarting']}

    Run Operation On BMC  ${operation}  ${count}

    Run Keyword If  '${operation}' == 'kernel_panic'
    ...  Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Standby

    Run Keyword If  '${operation}' == 'host_name'
    ...  Run Keywords  Wait Until Keyword Succeeds  5 min  10 sec
    ...  Verify Task Progress State  ${task_inv}  ${task_inv_dict['TaskCompleted']}  AND
    ...  Run Key  ${post_code_update_actions['BMC image']['OnReset']}  AND
    ...  Redfish.Login  AND
    ...  Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

    Run Keyword If  '${operation}' == 'https_certificate'
    ...  Run Keywords  Check Image Update Progress State
    ...  match_state='Updating'  image_id=${image_id}  AND
    ...  Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...  match_state='Enabled'  image_id=${image_id}  AND
    ...  Run Key  ${post_code_update_actions['BMC image']['OnReset']}  AND
    ...  Redfish.Login  AND
    ...  Redfish Verify BMC Version  ${IMAGE_FILE_PATH}


    ${after_update_activeswimage}=  Get Active Firmware Image

    ${status}=  Run Keyword And Return Status  Should Be Equal As Strings
    ...  ${before_update_activeswimage['ActiveSoftwareImage']['@odata.id']}
    ...  ${after_update_activeswimage['ActiveSoftwareImage']['@odata.id']}

    Run Keyword If  '${operation}' == 'kernel_panic'
    ...    Should Be True  ${status}
    ...  ELSE
    ...    Should Not Be True  ${status}

    Verify Get ApplyTime  OnReset

