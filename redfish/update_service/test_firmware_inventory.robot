*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Redfish Update Service Enabled
    [Documentation]  Verify "ServiceEnabled" is enabled.
    [Tags]  Verify_Update_Service_Enabled

    # Example:
    # "HttpPushUri": "/redfish/v1/UpdateService",
    # "Id": "UpdateService",
    # "Name": "Update Service",
    # "ServiceEnabled": true

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/UpdateService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Be Equal As Strings  ${resp.dict["ServiceEnabled"]}  ${True}
    Redfish.Logout


Verify Redfish Software Inventory Collection
    [Documentation]  Verify software inventory collection member and object entries.
    [Tags]  Verify_Redfish_Software_Inventory_Collection

    # Example:
    # {
    #    "@odata.type": "#SoftwareInventoryCollection.SoftwareInventoryCollection",
    #    "Members": [
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a3522998"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a7c79f71"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/ace821ef"
    #      }
    #   ],
    #   "Members@odata.count": 3,
    #   "Name": "Software Inventory Collection"
    # }

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    Should Be True  ${resp.dict["Members@odata.count"]} >= ${1}
    Length Should Be  ${resp.dict["Members"]}  ${resp.dict["Members@odata.count"]}
    Redfish.Logout


Redfish Software Inventory Status Check
    [Documentation]  Get firmware inventory entries and do health check status.
    [Tags]  Redfish_Software_Inventory_Status_Check

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    # Entries "Members@odata.count": 3,
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a3522998'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a7c79f71'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/ace821ef'}

    :FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
    \  ${resp_resource}=  Redfish.Get  ${resp.dict["Members"][${entry}]["@odata.id"]}
    \  Should Be Equal As Strings  ${resp_resource.status}  ${HTTP_OK}
    # Example:
    # "Status": {
    #     "Health": "OK",
    #     "HealthRollup": "OK",
    #     "State": "Enabled"
    # },
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["Health"]}  OK
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["HealthRollup"]}  OK
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["State"]}  Enabled
    Redfish.Logout
