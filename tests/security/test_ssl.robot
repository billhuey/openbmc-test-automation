*** Settings ***
Documentation     This testsuite is for testing SSL connection to OpenBMC
Suite Teardown    Delete All Sessions

Resource          ../../lib/rest_client.robot
Resource          ../../lib/resource.txt
Resource          ../../lib/openbmc_ffdc.robot
Test Teardown     Log FFDC

*** Test Cases ***
Test SSL Connection
    [Documentation]     This testcase is for testing the SSL connection to the
    ...     OpenBMC machine.
    [Tags]  Test_SSL_Connection
    Initialize OpenBMC

Test non-SSL Connection to port 80
    [Documentation]     This testcase is for test to check OpenBMC machine
    ...     will not accepts the non-secure connection that is with http to
    ...     port 80 and expect a connection error
    [Tags]  Test_non_SSL_Connection_to_port_80
    Create Session    openbmc    http://${OPENBMC_HOST}/    timeout=3
    Run Keyword And Expect Error    ConnectionError*   Get Request    openbmc   /list

Test non-SSL Connection to port 443
    [Documentation]     This testcase is for test to check OpenBMC machine
    ...     will not accepts the non-secure connection that is with http to
    ...     port 443 and expect 400 in response
    [Tags]  Test_non_SSL_Connection_to_port_443
    Create Session    openbmc    http://${OPENBMC_HOST}:443/
    ${resp}=    Get Request    openbmc   /list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_BAD_REQUEST}
    Should Be Equal     ${resp.content}     Bad Request
