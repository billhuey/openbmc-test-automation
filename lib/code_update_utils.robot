*** Settings ***
Documentation  BMC and PNOR update utilities keywords.

Library     code_update_utils.py
Library     OperatingSystem
Library     String
Variables   ../data/variables.py
Resource    rest_client.robot
Resource    openbmc_ffdc.robot

*** Keywords ***

Get Software Objects
    [Documentation]  Get the host software objects and return as a list.
    [Arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    # Example:
    # "data": [
    #      "/xyz/openbmc_project/software/f3b29aa8",
    #      "/xyz/openbmc_project/software/e49bc78e",
    # ],
    # Iterate the list and return the host object name path list.

    ${host_list}=  Create List
    ${sw_list}=  Read Properties  ${SOFTWARE_VERSION_URI}

    :FOR  ${index}  IN  @{sw_list}
    \  ${attr_purpose}=  Read Attribute  ${index}  Purpose  quiet=${1}
    \  Continue For Loop If  '${attr_purpose}' != '${version_type}'
    \  Append To List  ${host_list}  ${index}

    [Return]  ${host_list}


Get Software Objects Id
    [Documentation]  Get the software objects id and return as a list.
    [Arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #              (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #               "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    ${sw_id_list}=  Create List
    ${sw_list}=  Get Software Objects  ${version_type}

    :FOR  ${index}  IN  @{sw_list}
    \  Append To List  ${sw_id_list}  ${index.rsplit('/', 1)[1]}

    [Return]  ${sw_id_list}


Get Host Software Property
    [Documentation]  Return a dictionary of host software properties.
    [Arguments]  ${host_object}

    # Description of argument(s):
    # host_object  Host software object path.
    #             (e.g. "/xyz/openbmc_project/software/f3b29aa8").

    ${sw_attributes}=  Read Properties  ${host_object}
    [return]  ${sw_attributes}

Get Host Software Objects Details
    [Documentation]  Return software object details as a list of dictionaries.
    [Arguments]  ${quiet}=${QUIET}

    ${software}=  Create List

    ${pnor_details}=  Get Software Objects  ${VERSION_PURPOSE_HOST}
    :FOR  ${pnor}  IN  @{pnor_details}
    \  ${resp}=  OpenBMC Get Request  ${pnor}  quiet=${1}
    \  ${json}=  To JSON  ${resp.content}
    \  Append To List  ${software}  ${json["data"]}

    [Return]  ${software}

Set Host Software Property
    [Documentation]  Set the host software properties of a given object.
    [Arguments]  ${host_object}  ${sw_attribute}  ${data}

    # Description of argument(s):
    # host_object   Host software object name.
    # sw_attribute  Host software attribute name.
    #               (e.g. "Activation", "Priority", "RequestedActivation" etc).
    # data          Value to be written.

    ${args}=  Create Dictionary  data=${data}
    Write Attribute  ${host_object}  ${sw_attribute}  data=${args}


Set Property To Invalid Value And Verify No Change
    [Documentation]  Attempt to set a property and check that the value didn't
    ...              change.
    [Arguments]  ${property}  ${version_type}

    # Description of argument(s):
    # property      The property to attempt to set.
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    ${software_objects}=  Get Software Objects  version_type=${version_type}
    ${prev_properties}=  Get Host Software Property  @{software_objects}[0]
    Run Keyword And Expect Error  500 != 200
    ...  Set Host Software Property  @{software_objects}[0]  ${property}  foo
    ${cur_properties}=  Get Host Software Property  @{software_objects}[0]
    Should Be Equal As Strings  &{prev_properties}[${property}]
    ...  &{cur_properties}[${property}]


Upload And Activate Image
    [Documentation]  Upload an image to the BMC and activate it with REST.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path  The path to the image tarball to upload and activate.

    OperatingSystem.File Should Exist  ${image_file_path}
    ${image_version}=  Get Version Tar  ${image_file_path}

    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}
    Upload Image To BMC  /upload/image  data=${image_data}
    ${ret}  ${version_id}=  Verify Image Upload  ${image_version}
    Should Be True  ${ret}

    # Verify the image is 'READY' to be activated.
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[Activation]  ${READY}

    # Request the image to be activated.
    ${args}=  Create Dictionary  data=${REQUESTED_ACTIVE}
    Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  RequestedActivation  data=${args}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[RequestedActivation]
    ...  ${REQUESTED_ACTIVE}

    # Verify code update was successful and Activation state is Active.
    Wait For Activation State Change  ${version_id}  ${ACTIVATING}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[Activation]  ${ACTIVE}


Activate Image And Verify No Duplicate Priorities
    [Documentation]  Upload an image, and then check that no images have the
    ...              same priority.
    [Arguments]  ${image_file_path}  ${image_purpose}

    # Description of argument(s):
    # image_file_path  The path to the image to upload.
    # image_purpose    The purpose in the image's MANIFEST file.

    Upload And Activate Image  ${image_file_path}
    Verify No Duplicate Image Priorities  ${image_purpose}


Set Same Priority For Multiple Images
    [Documentation]  Find two images, set the priorities to be the same, and
    ...              verify that the priorities are not the same.
    [Arguments]  ${version_purpose}

    # Description of argument(s):
    # version_purpose  Either BMC or host version purpose.
    #                  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #                        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    # Make sure we have more than two images.
    ${software_objects}=  Get Software Objects  version_type=${version_purpose}
    ${num_images}=  Get Length  ${software_objects}
    Should Be True  1 < ${num_images}
    ...  msg=Only found one image on the BMC with purpose ${version_purpose}.

    # Set the priority of the second image to the priority of the first.
    ${properties}=  Get Host Software Property  @{software_objects}[0]
    Set Host Software Property  @{software_objects}[1]  Priority
    ...  &{properties}[Priority]
    Verify No Duplicate Image Priorities  ${version_purpose}

    # Set the priority of the first image back to what it was before
    Set Host Software Property  @{software_objects}[0]  Priority
    ...  &{properties}[Priority]


Delete Software Object
    [Documentation]  Deletes an image from the BMC.
    [Arguments]  ${software_object}

    # Description of argument(s):
    # software_object  The URI to the software image to delete.

    ${arglist}=  Create List
    ${args}=  Create Dictionary  data=${arglist}
    ${resp}=  OpenBMC Post Request  ${software_object}/action/delete
    ...  data=${args}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete Image And Verify
    [Documentation]  Delete an image from the BMC and verify that it was
    ...              removed from software and the /tmp/images directory.
    [Arguments]  ${software_object}  ${version_type}

    # Description of argument(s):
    # software_object        The URI of the software object to delete.
    # version_type  The type of the software object, e.g.
    #               xyz.openbmc_project.Software.Version.VersionPurpose.Host
    #               or xyz.openbmc_project.Software.Version.VersionPurpose.BMC.

    Log To Console  Deleteing ${software_object}

    # Delete the image.
    Delete Software Object  ${software_object}
    # TODO: If/when we don't have to delete twice anymore, take this out
    Run Keyword And Ignore Error  Delete Software Object  ${software_object}

    # Verify that it's gone from software.
    ${software_objects}=  Get Software Objects  version_type=${version_type}
    Should Not Contain  ${software_objects}  ${software_object}

    # Check that there is no file in the /tmp/images directory.
    ${image_id}=  Fetch From Right  ${software_object}  /
    BMC Execute Command
    ...  [ ! -d "/tmp/images/${image_id}" ]


Check Error And Collect FFDC
    [Documentation]  Collect FFDC if error log exists.

    ${status}=  Run Keyword And Return Status  Error Logs Should Not Exist
    Run Keyword If  '${status}' == 'False'  FFDC
    Delete Error Logs
