*** Settings ***
Documentation     Verify REST services Get/Put/Post/Delete.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.txt
Library           Collections
Test Teardown     FFDC On Test Case Fail

*** Variables ***

*** Test Cases ***

REST Login Session To BMC
    [Documentation]  Test REST session log-in.
    [Tags]  REST_Login_Session_To_BMC

    Initialize OpenBMC
    # Raw GET REST operation to verify session is established.
    ${resp}=  Get Request  openbmc  /xyz/openbmc_project/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


REST Logout Session To BMC
    [Documentation]  Test REST session log-out.
    [Tags]  REST_Logout_Session_To_BMC

    Initialize OpenBMC
    Log Out OpenBMC
    # Raw GET REST operation to verify session is logout.
    ${resp}=  Get Request  openbmc  /xyz/openbmc_project/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_UNAUTHORIZED}


REST Delete All Sessions And Expect Error
    [Documentation]  Test REST empty cache using delete operation.
    [Tags]  REST_Delete_All_Sessions_And_Expect_Error

    # Throws exception:
    # Non-existing index or alias 'openbmc'.

    Initialize OpenBMC
    Delete All Sessions
    # Raw GET REST operation and expect exception error.
    Run Keyword And Expect Error
    ...  Non-existing index or alias 'openbmc'.
    ...  Get Request  openbmc  /xyz/openbmc_project/


Verify REST JSON Data On Success
    [Documentation]  Verify JSON data success response messages.
    [Tags]  Verify_REST_JSON_Data_On_Success
    # Example:
    # Response code:200, Content:{
    # "data": [
    #         "/xyz/openbmc_project/sensors",
    #         "/xyz/openbmc_project/inventory",
    #         "/xyz/openbmc_project/software",
    #         "/xyz/openbmc_project/object_mapper",
    #         "/xyz/openbmc_project/logging"
    #         ],
    # "message": "200 OK",
    # "status": "ok"
    # }

    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}
    Should Be Equal As Strings  ${jsondata["message"]}  200 OK
    Should Be Equal As Strings  ${jsondata["status"]}  ok


Verify REST JSON Data On Failure
    [Documentation]  Verify JSON data failure response messages.
    [Tags]  Verify_REST_JSON_Data_On_Failure
    # Example:
    # Response code:404, Content:{
    # "data": {
    #        "description": "org.freedesktop.DBus.Error.FileNotFound: path or object not found: /xyz/idont/exist"
    #         },
    # "message": "404 Not Found",
    # "status": "error"
    # }

    ${resp}=  OpenBMC Get Request  /xyz/idont/exist/
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings
    ...  ${jsondata["data"]["description"]}  org.freedesktop.DBus.Error.FileNotFound: path or object not found: /xyz/idont/exist
    Should Be Equal As Strings  ${jsondata["message"]}  404 Not Found
    Should Be Equal As Strings  ${jsondata["status"]}  error


REST Message JSON Format Compliance Test
    [Documentation]  Verify REST message are JSON format compliance.
    [Tags]  REST_Message_JSON_Format_Compliance_Test
    # For testing if the REST message is JSON format compliance using a
    # generic BMC state path /xyz/openbmc_project/state object and path
    # walking through to ensure the parent object, trailing slash and
    # attribute message response are intact.

    # Object attribute data.
    # Example:
    # Response code:200, Content:{
    #   "data": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #   },
    #   "message": "200 OK",
    #   "status": "ok"
    # }
    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/state/bmc0
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}
    Should Be Equal As Strings  ${jsondata["message"]}  200 OK
    Should Be Equal As Strings  ${jsondata["status"]}  ok

    # Object trailing slash attribute data.
    # Example:
    # Response code:200, Content:{
    #    "data": [],
    #    "message": "200 OK",
    #    "status": "ok"
    # }
    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/state/bmc0/
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Empty  ${jsondata["data"]}
    Should Be Equal As Strings  ${jsondata["message"]}  200 OK
    Should Be Equal As Strings  ${jsondata["status"]}  ok

    # Attribute data.
    # Example:
    # Response code:200, Content:{
    #   "data": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #   "message": "200 OK",
    #   "status": "ok"
    # }
    ${resp}=  OpenBMC Get Request
    ...  /xyz/openbmc_project/state/bmc0/attr/CurrentBMCState
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}
    Should Be Equal As Strings  ${jsondata["message"]}  200 OK
    Should Be Equal As Strings  ${jsondata["status"]}  ok


Check Response Codes HTTP_UNSUPPORTED_MEDIA_TYPE
    [Documentation]  REST "Post" response status test for
    ...              HTTP_UNSUPPORTED_MEDIA_TYPE.
    [Tags]  Check_Response_Codes_415

    # Example:
    # Response code:415, Content:{
    # "data": {
    #         "description": "Expecting content type 'application/octet-stream', got 'application/json'"
    #         },
    # "message": "415 Unsupported Media Type",
    # "status": "error"
    # }

    Initialize OpenBMC

    # Create the REST payload headers and EMPTY data
    ${data}=  Create Dictionary  data  ${EMPTY}
    ${headers}=  Create Dictionary  Content-Type=application/json
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Post Request  openbmc  /upload/image  &{data}
    Should Be Equal As Strings
    ...  ${resp.status_code}  ${HTTP_UNSUPPORTED_MEDIA_TYPE}

    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${jsondata["data"]["description"]}
    ...  Expecting content type 'application/octet-stream', got 'application/json'
    Should Be Equal As Strings
    ...  ${jsondata["message"]}  415 Unsupported Media Type
    Should Be Equal As Strings  ${jsondata["status"]}  error


Get Response Codes
    [Documentation]  REST "Get" response status test.
    #--------------------------------------------------------------------
    # Expect status      URL Path
    #--------------------------------------------------------------------
    ${HTTP_OK}           /
    ${HTTP_OK}           /xyz/
    ${HTTP_OK}           /xyz/openbmc_project/
    ${HTTP_OK}           /xyz/openbmc_project/enumerate
    ${HTTP_NOT_FOUND}    /i/dont/exist/

    [Tags]  Get_Response_Codes
    [Template]  Execute Get And Check Response


Get Data
    [Documentation]  REST "Get" request url and expect the
    ...              response OK and data non empty.
    #--------------------------------------------------------------------
    # URL Path
    #--------------------------------------------------------------------
    /xyz/openbmc_project/
    /xyz/openbmc_project/list
    /xyz/openbmc_project/enumerate

    [Tags]  Get_Data
    [Template]  Execute Get And Check Data


Get Data Validation
    [Documentation]  REST "Get" request url and expect the
    ...              pre-defined string in response data.
    #--------------------------------------------------------------------
    # URL Path                  Expect Data
    #--------------------------------------------------------------------
    /xyz/openbmc_project/       /xyz/openbmc_project/logging
    /i/dont/exist/              path or object not found: /i/dont/exist

    [Tags]  Get_Data_Validation
    [Template]  Execute Get And Verify Data


Put Response Codes
    [Documentation]  REST "Put" request url and expect the REST pre-defined
    ...              codes.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /i/dont/exist/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/list
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate

    [Tags]  Put_Response_Codes
    [Template]  Execute Put And Check Response


Put Data Validation
    [Documentation]  REST "Put" request url and expect success.
    #--------------------------------------------------------------------
    # URL Path                      Parm Data
    #--------------------------------------------------------------------
    /xyz/openbmc_project/state/host0/attr/RequestedHostTransition    xyz.openbmc_project.State.Host.Transition.Off

    [Tags]  Put_Data_Validation
    [Template]  Execute Put And Expect Success


Post Response Code
    [Documentation]  REST Post request url and expect the
    ...              REST response code pre define.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /i/dont/exist/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate

    [Tags]  Post_Response_Codes
    [Template]  Execute Post And Check Response


Delete Response Code
    [Documentation]  REST "Delete" request url and expect the
    ...              REST response code pre define.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/nothere/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/openbmc_project/list
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/openbmc_project/enumerate

    [Tags]  Delete_Response_Codes
    [Template]  Execute Delete And Check Response


*** Keywords ***

Execute Get And Check Response
    [Documentation]  Request "Get" url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Get And Check Data
    [Documentation]  Request "Get" url path and expect non empty data.
    [Arguments]  ${url_path}
    # Description of arguments:
    # url_path     URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}

Execute Get And Verify Data
    [Documentation]  Request "Get" url path and verify data.
    [Arguments]  ${url_path}  ${expected_response_code}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    ${jsondata}=  To JSON  ${resp.content}
    Run Keyword If  '${resp.status_code}' == '${HTTP_OK}'
    ...  Should Contain  ${jsondata["data"]}  ${expected_response_code}
    ...  ELSE
    ...  Should Contain  ${jsondata["data"]["description"]}  ${expected_response_code}

Execute Put And Check Response
    [Documentation]  Request "Put" url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Put Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Put And Expect Success
    [Documentation]  Request "Put" on url path.
    [Arguments]  ${url_path}  ${parm}
    # Description of arguments:
    # url_path     URL path.
    # parm         Value/string to be set.
    # expected_response_code   Expected REST status codes.
    ${parmDict}=  Create Dictionary  data=${parm}
    ${resp}=  Openbmc Put Request  ${url_path}  data=${parmDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Execute Post And Check Response
    [Documentation]  Request Post url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Post Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Post And Check Data
    [Arguments]  ${url_path}  ${parm}
    [Documentation]  Request Post on url path and expected non empty data.
    # Description of arguments:
    # url_path     URL path.
    ${data}=  Create Dictionary  data=@{parm}
    ${resp}=  Openbmc Post Request  ${url_path}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}

Execute Delete And Check Response
    [Documentation]  Request "Delete" url path and expected REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path     URL path.
    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Delete Request  ${url_path}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}
