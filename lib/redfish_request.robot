*** Settings ***

Documentation     Redfish request library.

Resource          openbmc_ffdc.robot
Resource          bmc_redfish_resource.robot
Resource          rest_response_code.robot

*** Keywords ***

Redfish Generic Login Request
    [Documentation]  Do Redfish login request..
    [Arguments]   ${user_name}  ${password}

    ${client_id}=  Create Dictionary  ClientID=None
    ${oem_data}=  Create Dictionary  OpenBMC=${client_id}
    ${data}=  Create Dictionary  UserName=${user_name}  Password=${password}  Oem=${oem_data}

    Set Test Variable  ${uri}  /redfish/v1/SessionService/Sessions
    ${resp}=  redfish_request_utils.Request_Login  headers=None  url=uri  credential=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_CREATED}

    [Return]  ${resp}


Redfish Generic Session Request
    [Documentation]  Do Redfish login request and store the session details..
    [Arguments]   ${user_name}  ${password}

    ${session_dict}=   Create Dictionary
    ${session_resp}=   Redfish Generic Login Request  ${user_name}  ${password}

    ${auth_token}=  Create Dictionary  X-Auth-Token  ${session_resp.headers['X-Auth-Token']}

    Set To Dictionary  ${session_dict}  headers  ${auth_token}
    Set To Dictionary  ${session_dict}  Location  ${session_resp.headers['Location']}

    ${content}=  To JSON  ${session_resp.content}

    Set To Dictionary  ${session_dict}  Content  ${content}

    Set Global Variable  ${active_session_info}  ${session_dict}
    Append To List  ${session_dict_list}  ${session_dict}

    [Return]  ${session_dict}
