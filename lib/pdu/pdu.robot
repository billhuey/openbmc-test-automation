*** Settings ***
Documentation           Generic PDU library

Resource        ../../lib/resource.txt

*** Keywords ***
Validate Prereq
    ${PDU_VAR_LIST} =    Create List    PDU_TYPE    PDU_IP  PDU_USERNAME    PDU_PASSWORD    PDU_SLOT_NO
    : FOR    ${PDU_VAR}    IN    @{PDU_VAR_LIST}
    \    Should Not Be Empty    ${${PDU_VAR}}   msg=Unable to find variable ${PDU_VAR}

PDU Power Cycle
    Validate Prereq
    Import Resource  ${CURDIR}/../../lib/pdu/${PDU_TYPE}.robot
    Power Cycle
