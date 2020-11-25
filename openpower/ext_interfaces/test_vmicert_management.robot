*** Settings ***

Documentation    VMI certificate exchange tests.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Suite Teardown Execution


*** Variables ***

# users           User Name               password
@{ADMIN}          admin_user              TestPwd123
@{OPERATOR}       operator_user           TestPwd123
@{ReadOnly}       readonly_user           TestPwd123
@{NoAccess}       noaccess_user           TestPwd123
&{USERS}          Administrator=${ADMIN}  Operator=${OPERATOR}  ReadOnly=${ReadOnly}
...               NoAccess=${NoAccess}
${VMI_BASE_URI}   /ibm/v1/
${CSR_FILE}       csr_server.csr
${CSR_KEY}        csr_server.key

*** Test Cases ***

Get CSR Request Signed By VMI And Verify
    [Documentation]  Get CSR request signed by VMI using different user roles and verify.
    [Tags]  Get_CSR_Request_Signed_By_VMI_And_Verify
    [Setup]  Redfish Power On
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr  valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_OK}

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}


Get Root Certificate Using Different Privilege Users Roles
    [Documentation]  Get root certificate using different users.
    [Tags]  Get_Root_Certificate_Using_Different_Users
    [Setup]  Redfish Power On
    [Template]  Get Root Certificate

    # username     password    force_create  valid_csr  valid_status_code
    # Request root certificate from admin user.
    admin_user     TestPwd123  ${True}       ${True}    ${HTTP_OK}

    # Request root certificate from operator user.
    operator_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from ReadOnly user.
    readonly_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from NoAccess user.
    noaccess_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}


Send CSR Request When VMI Is Off And Verify
    [Documentation]  Send CSR signing request to VMI when it is off and expect an error.
    [Tags]  Get_CSR_Request_When_VMI_Is_Off_And_verify
    [Setup]  Redfish Power Off
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr  valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_INTERNAL_SERVER_ERROR}

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${True}    ${HTTP_INTERNAL_SERVER_ERROR}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${True}    ${HTTP_INTERNAL_SERVER_ERROR}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${True}    ${HTTP_INTERNAL_SERVER_ERROR}

Get Corrupted CSR Request Signed By VMI And Verify
    [Documentation]  Send corrupted CSR for signing and expect an error.
    [Tags]  Get_Corrupted_CSR_Request_Signed_By_VMI_And_Verify
    [Setup]  Redfish Power On
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr   valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${False}    ${HTTP_INTERNAL_SERVER_ERROR}

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}



*** Keywords ***

Generate CSR String
    [Documentation]  Generate a csr string.

    # Note: Generates and returns csr string.
    ${ssl_cmd}=  Set Variable  openssl req -new -newkey rsa:2048 -nodes -keyout ${CSR_KEY} -out ${CSR_FILE}
    ${ssl_sub}=  Set Variable
    ...  -subj "/C=XY/ST=Abcd/L=Efgh/O=ABC/OU=Systems/CN=abc.com/emailAddress=xyz@xx.ABC.com"

    # Run openssl command to create a new private key and use that to generate a CSR string
    # in server.csr file.
    ${output}=  Run  ${ssl_cmd} ${ssl_sub}
    ${csr}=  OperatingSystem.Get File  ${CSR_FILE}

    [Return]  ${csr}


Send CSR To VMI And Get Signed
    [Arguments]  ${csr}  ${force_create}  ${username}  ${password}

    # Description of argument(s):
    # csr                    Certificate request from client to VMI.
    # force_create           Create a new REST session if True.
    # username               Username to create a REST session.
    # password               Password to create a REST session.

    Run Keyword If  "${XAUTH_TOKEN}" != "${EMPTY}" or ${force_create} == ${True}
    ...  Initialize OpenBMC  rest_username=${username}  rest_password=${password}

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    ...  Content-Type=application/json

    ${cert_uri}=  Set Variable  ${VMI_BASE_URI}Host/Actions/SignCSR

    # For SignCSR request, we need to pass CSR string generated by openssl command.
    ${csr_data}=  Create Dictionary  CsrString  ${csr}
    Set To Dictionary  ${data}  data  ${csr_data}

    ${resp}=  Post Request  openbmc  ${cert_uri}  &{data}  headers=${headers}

    [Return]  ${resp}


Get Root Certificate
    [Documentation]  Get root certificate from VMI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${force_create}=${False}  ${valid_csr}=${True}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # cert_type          Type of the certificate requesting. eg. root or SignCSR.
    # username           Username to create a REST session.
    # password           Password to create a REST session.
    # force_create       Create a new REST session if True.
    # valid_csr          Uses valid CSR string in the REST request if True.
    #                    This is not applicable for root certificate.
    # valid_status_code  Expected status code from REST request.

    Run Keyword If  "${XAUTH_TOKEN}" != "${EMPTY}" or ${force_create} == ${True}
    ...  Initialize OpenBMC  rest_username=${username}  rest_password=${password}

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    ...  Content-Type=application/json

    ${cert_uri}=  Set Variable  ${VMI_BASE_URI}Host/Certificate/root

    ${resp}=  Get Request  openbmc  ${cert_uri}  &{data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${valid_status_code}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}

    ${cert}=  Evaluate  json.loads('''${resp.text}''', strict=False)  json
    Should Contain  ${cert["Certificate"]}  BEGIN CERTIFICATE
    Should Contain  ${cert["Certificate"]}  END CERTIFICATE


Get Subject
    [Documentation]  Generate a csr string.
    [Arguments]  ${file_name}  ${is_csr_file}

    # Description of argument(s):
    # file_name          Name of CSR or signed CERT file.
    # is_csr_file        A True value means a CSR while a False is for signed CERT file.

    ${subject}=  Run Keyword If  ${is_csr_file}  Run  openssl req -in ${file_name} -text -noout | grep Subject:
    ...   ELSE  Run  openssl x509 -in ${file_name} -text -noout | grep Subject:

    [Return]  ${subject}


Get Public Key
    [Documentation]  Generate a csr string.
    [Arguments]  ${file_name}  ${is_csr_file}

    # Description of argument(s):
    # file_name          Name of CSR or CERT file.
    # is_csr_file        A True value means a CSR while a False is for signed CERT file.

    ${PublicKey}=  Run Keyword If  ${is_csr_file}  Run  openssl req -in ${file_name} -noout -pubkey
    ...   ELSE  Run  openssl x509 -in ${file_name} -noout -pubkey

    [Return]  ${PublicKey}


Get Certificate Signed By VMI
    [Documentation]  Get signed certificate from VMI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${force_create}=${False}  ${valid_csr}=${True}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # cert_type          Type of the certificate requesting. eg. root or SignCSR.
    # username           Username to create a REST session.
    # password           Password to create a REST session.
    # force_create       Create a new REST session if True.
    # valid_csr          Uses valid CSR string in the REST request if True.
    #                    This is not applicable for root certificate.
    # valid_status_code  Expected status code from REST request.

    Set Test Variable  ${CSR}  CSR
    Set Test Variable  ${CORRUPTED_CSR}  CORRUPTED_CSR

    ${CSR}=  Generate CSR String
    ${csr_left}  ${csr_right}=  Split String From Right  ${CSR}  ==  1
    ${CORRUPTED_CSR}=  Catenate  SEPARATOR=  ${csr_left}  \N  ${csr_right}

    # For SignCSR request, we need to pass CSR string generated by openssl command
    ${csr_str}=  Set Variable If  ${valid_csr} == ${True}  ${CSR}  ${CORRUPTED_CSR}

    ${resp}=  Send CSR To VMI And Get Signed  ${csr_str}  ${force_create}  ${username}  ${password}

    Should Be Equal As Strings  ${resp.status_code}  ${valid_status_code}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}

    ${cert}=  Evaluate  json.loads('''${resp.text}''', strict=False)  json
    Should Contain  ${cert["Certificate"]}  BEGIN CERTIFICATE
    Should Contain  ${cert["Certificate"]}  END CERTIFICATE

    # Now do subject and public key verification
    ${subject_csr}=  Get Subject  ${CSR_FILE}  True
    ${pubKey_csr}=  Get Public Key  ${CSR_FILE}  True

    # create a crt file with certificate string
    ${signed_cert}=  Set Variable  ${cert["Certificate"]}

    Create File  test_certificate.crt  ${signed_cert}
    ${subject_signed_csr}=  Get Subject  test_certificate.crt  False
    ${pubKey_signed_csr}=  Get Public Key  test_certificate.crt  False

    Should be equal as strings    ${subject_signed_csr}    ${subject_csr}
    Should be equal as strings    ${pubKey_signed_csr}     ${pubKey_csr}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Create different user accounts.
    Redfish.Login
    Create Users With Different Roles  users=${USERS}  force=${True}


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Delete BMC Users Via Redfish  users=${USERS}
    Delete All Sessions
    Redfish.Logout
