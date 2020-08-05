*** Settings ***

Documentation    Test Lock Management feature of Management Console on BMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Suite Setup      Run Keyword And Ignore Error  Delete All Redfish Sessions
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Run Keyword And Ignore Error  Delete All Redfish Sessions

*** Variables ***

# Data-sets for testing different test cases.
&{LOCKALL_LEN1}                   LockFlag=LockAll                SegmentLength=${1}
&{LOCKALL_LEN2}                   LockFlag=LockAll                SegmentLength=${2}
&{LOCKALL_LEN3}                   LockFlag=LockAll                SegmentLength=${3}
&{LOCKALL_LEN4}                   LockFlag=LockAll                SegmentLength=${4}
&{LOCKALL_LEN5}                   LockFlag=LockAll                SegmentLength=${5}

&{LOCKALL_INVALID_LOCKFLAG1}      LockFlag=LocAll                 SegmentLength=${2}
&{LOCKALL_INVALID_LOCKFLAG2}      LockFlag=LOCKALL                SegmentLength=${3}
&{LOCKALL_INVALID_LOCKFLAG3}      LOCKFLAG=LockAll                SegmentLength=${4}
&{LOCKSAME_INVALID_LOCKFLAG3}     Lock=LockSame                   SegmentLength=${1}
&{LOCKSAME_INVALID_LOCKFLAG4}     Lock=LockSame                   SegmentLength=${True}

&{LOCKSAME_LEN1}                  LockFlag=LockSame               SegmentLength=${1}
&{LOCKSAME_LEN2}                  LockFlag=LockSame               SegmentLength=${2}
&{LOCKSAME_LEN3}                  LockFlag=LockSame               SegmentLength=${3}
&{LOCKSAME_LEN4}                  LockFlag=LockSame               SegmentLength=${4}
&{LOCKSAME_INVALID_LEN1}          LockFlag=LockSame               SegmentLength=${0}
&{LOCKSAME_INVALID_LEN2}          LockFlag=LockSame               SegmentLength=${5}
&{LOCKSAME_INVALID_LEN_STR}       LockFlag=LockSame               SegmentLength=2
&{LOCKSAME_INVALID_LEN_NEG}       LockFlag=LockSame               SegmentLength=${-3}
&{LOCKSAME_INVALID_LEN_BOOL}      Lock=LockSame                   SegmentLength=${True}

&{DONTLOCK_LEN1}                  LockFlag=DontLock               SegmentLength=${1}
&{DONTLOCK_LEN2}                  LockFlag=DontLock               SegmentLength=${2}
&{DONTLOCK_LEN3}                  LockFlag=DontLock               SegmentLength=${3}
&{DONTLOCK_LEN4}                  LockFlag=DontLock               SegmentLength=${4}
&{DONTLOCK_INVALID_LEN}           LockFlag=DontLock               SegmentLength=${5}
&{DONTLOCK_INVALID_LEN_BOOL}      LockFlag=DONTLOCK               SegmentLength=${False}
&{DONTLOCK_INVALID_LOCKFLAG}      LOCKFLAG=LockAll                SegmentLength=${4}

@{ONE_SEG_FLAG_ALL}               ${LOCKALL_LEN1}
@{ONE_SEG_FLAG_SAME}              ${LOCKSAME_LEN3}
@{ONE_SEG_FLAG_DONT}              ${DONTLOCK_LEN4}

@{TWO_SEG_FLAG_1}                 ${LOCKALL_LEN1}                 ${LOCKSAME_LEN2}
@{TWO_SEG_FLAG_2}                 ${DONTLOCK_LEN3}                ${LOCKALL_LEN1}
@{TWO_SEG_FLAG_3}                 ${DONTLOCK_LEN4}                ${LOCKSAME_LEN3}
@{TWO_SEG_FLAG_4}                 ${DONTLOCK_INVALID_LEN}         ${LOCKSAME_LEN3}
@{TWO_SEG_FLAG_5}                 ${DONTLOCK_LEN2}                ${LOCKSAME_INVALID_LEN1}

@{TWO_SEG_FLAG_INVALID1}          ${DONTLOCK_LEN4}                ${LOCKSAME_INVALID_LEN1}
@{TWO_SEG_FLAG_INVALID2}          ${LOCKALL_LEN5}                 ${DONTLOCK_LEN1}
@{TWO_SEG_FLAG_INVALID3}          ${DONTLOCK_LEN1}                ${LOCKALL_INVALID_LOCKFLAG1}
@{TWO_SEG_FLAG_INVALID4}          ${DONTLOCK_LEN2}                ${LOCKALL_INVALID_LOCKFLAG2}
@{TWO_SEG_FLAG_INVALID5}          ${DONTLOCK_LEN2}                ${LOCKALL_INVALID_LOCKFLAG3}
@{TWO_SEG_FLAG_INVALID6}          ${LOCKALL_LEN3}                 ${LOCKSAME_INVALID_LOCKFLAG3}
@{TWO_SEG_FLAG_INVALID7}          ${DONTLOCK_LEN2}                ${LOCKSAME_INVALID_LOCKFLAG4}
@{TWO_SEG_FLAG_INVALID8}          ${DONTLOCK_INVALID_LOCKFLAG}    ${LOCKSAME_INVALID_LEN_BOOL}
@{TWO_SEG_FLAG_INVALID9}          ${DONTLOCK_LEN2}                ${LOCKSAME_INVALID_LOCKFLAG4}

@{THREE_SEG_FLAG_1}               ${LOCKALL_LEN1}                 @{TWO_SEG_FLAG_3}
@{THREE_SEG_FLAG_2}               ${LOCKSAME_LEN4}                @{TWO_SEG_FLAG_2}
@{THREE_SEG_FLAG_3}               ${DONTLOCK_LEN3}                @{TWO_SEG_FLAG_1}

@{FOUR_SEG_FLAG_1}                ${LOCKALL_LEN1}                 @{THREE_SEG_FLAG_2}
@{FOUR_SEG_FLAG_2}                ${LOCKSAME_LEN4}                @{THREE_SEG_FLAG_3}
@{FOUR_SEG_FLAG_3}                ${DONTLOCK_LEN3}                @{THREE_SEG_FLAG_1}

@{FIVE_SEG_FLAG_1}                ${LOCKALL_LEN1}                 @{FOUR_SEG_FLAG_2}
@{FIVE_SEG_FLAG_2}                ${LOCKSAME_LEN4}                @{FOUR_SEG_FLAG_3}
@{FIVE_SEG_FLAG_3}                ${DONTLOCK_LEN3}                @{FOUR_SEG_FLAG_1}

@{SIX_SEG_FLAG_1}                 ${LOCKALL_LEN1}                 @{FIVE_SEG_FLAG_2}
@{SIX_SEG_FLAG_2}                 ${LOCKSAME_LEN4}                @{FIVE_SEG_FLAG_3}
@{SIX_SEG_FLAG_3}                 ${DONTLOCK_LEN3}                @{FIVE_SEG_FLAG_1}

@{SEVEN_SEG_FLAG_1}               ${LOCKALL_LEN1}                 @{SIX_SEG_FLAG_2}
@{SEVEN_SEG_FLAG_2}               ${LOCKSAME_LEN4}                @{SIX_SEG_FLAG_3}
@{SEVEN_SEG_FLAG_3}               ${DONTLOCK_LEN3}                @{SIX_SEG_FLAG_1}

# Different messages to be verified.
${PROP_REQ_ERR}         is a required property and must be included in the request.
${PROP_ERR}             is not in the list of valid properties for the resource.
${PROP_TYPE_ERR}        is of a different type than the property can accept.

# Build error patterns list.
@{EMPTY_LIST}
@{ERR_PATTERN1}                   ${PROP_REQ_ERR}                ${PROP_ERR}
@{ERR_PATTERN2}                   ${PROP_TYPE_ERR}
@{ERR_PATTERN3}                   ${PROP_REQ_ERR}                ${PROP_ERR}                 ${PROP_TYPE_ERR}

# Dictionary of Locks with Transaction ID as key and Session ID as a value.
&{LOCKS}


*** Test Cases ***

Acquire And Release Different Read Locks
    [Documentation]  Acquire and release different read locks.
    [Tags]  Acquire_And_Release_Different_Read_Locks
    [Template]  Acquire And Release Lock

    # lock  seg_flags                     resource_id  hmc_id  exp_status_code      err_msgs         new_sess
    # type                                                                                            req
    Read    ${ONE_SEG_FLAG_ALL}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${ONE_SEG_FLAG_SAME}          ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${ONE_SEG_FLAG_DONT}          ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_1}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_2}             ${234}       hmc-id  ${HTTP_OK}           ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_3}             ${234}       hmc-id  ${HTTP_OK}           ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_4}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_5}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${THREE_SEG_FLAG_1}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${THREE_SEG_FLAG_2}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${THREE_SEG_FLAG_3}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FOUR_SEG_FLAG_1}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FOUR_SEG_FLAG_2}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FOUR_SEG_FLAG_3}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FIVE_SEG_FLAG_1}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FIVE_SEG_FLAG_2}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${FIVE_SEG_FLAG_3}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SIX_SEG_FLAG_1}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SIX_SEG_FLAG_2}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SIX_SEG_FLAG_3}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SEVEN_SEG_FLAG_1}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SEVEN_SEG_FLAG_2}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${SEVEN_SEG_FLAG_3}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${LOCKSAME_INVALID_LEN1}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${LOCKSAME_INVALID_LEN_STR}   ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}
    Read    ${LOCKSAME_INVALID_LEN_NEG}   ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}
    Read    ${LOCKSAME_INVALID_LEN_BOOL}  ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}
    Read    ${DONTLOCK_INVALID_LEN_BOOL}  ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}
    Read    ${TWO_SEG_FLAG_INVALID1}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_INVALID2}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_INVALID3}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_INVALID4}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${EMPTY_LIST}    ${True}
    Read    ${TWO_SEG_FLAG_INVALID5}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN1}  ${True}
    Read    ${TWO_SEG_FLAG_INVALID6}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN1}  ${True}
    Read    ${TWO_SEG_FLAG_INVALID7}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN3}  ${True}
    Read    ${TWO_SEG_FLAG_INVALID8}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN1}  ${True}
    Read    ${TWO_SEG_FLAG_INVALID9}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}
    Read    ${TWO_SEG_FLAG_3}             234          hmc-id  ${HTTP_BAD_REQUEST}  ${ERR_PATTERN2}  ${True}


Acquire And Release Different Write Locks
    [Documentation]  Acquire and release different write locks.
    [Tags]  Acquire_And_Release_Different_Write_Locks
    [Template]  Acquire And Release Lock

    # lock  seg_flags                    resource_id  hmc_id  exp_status_code       err_msgs         new_sess
    # type                                                                                            req
    Write  ${ONE_SEG_FLAG_ALL}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${ONE_SEG_FLAG_SAME}          ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${ONE_SEG_FLAG_DONT}          ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_1}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_2}             ${234}       hmc-id  ${HTTP_OK}            ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_3}             ${234}       hmc-id  ${HTTP_OK}            ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_INVALID4}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${THREE_SEG_FLAG_1}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${THREE_SEG_FLAG_2}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${THREE_SEG_FLAG_3}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FOUR_SEG_FLAG_1}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FOUR_SEG_FLAG_2}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FOUR_SEG_FLAG_3}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FIVE_SEG_FLAG_1}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FIVE_SEG_FLAG_2}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${FIVE_SEG_FLAG_3}            ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SIX_SEG_FLAG_1}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SIX_SEG_FLAG_2}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SIX_SEG_FLAG_3}             ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SEVEN_SEG_FLAG_1}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SEVEN_SEG_FLAG_2}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${SEVEN_SEG_FLAG_3}           ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${LOCKSAME_INVALID_LEN1}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${LOCKSAME_INVALID_LEN_STR}   ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${LOCKSAME_INVALID_LEN_NEG}   ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${LOCKSAME_INVALID_LEN_BOOL}  ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${DONTLOCK_INVALID_LEN_BOOL}  ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_INVALID1}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_INVALID2}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${EMPTY_LIST}    ${True}
    Write  ${TWO_SEG_FLAG_INVALID8}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${ERR_PATTERN1}  ${True}
    Write  ${TWO_SEG_FLAG_INVALID5}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${ERR_PATTERN1}  ${True}
    Write  ${TWO_SEG_FLAG_INVALID9}      ${234}       hmc-id  ${HTTP_BAD_REQUEST}   ${ERR_PATTERN2}  ${True}
    Write  ${TWO_SEG_FLAG_3}             234          hmc-id  ${HTTP_BAD_REQUEST}   ${ERR_PATTERN2}  ${True}


Verify GetLockList Returns An Empty Record For An Invalid Session Id
    [Documentation]  Verify GetLockList returns an empty record for an invalid session id.
    [Tags]  Verify_GetLockList_Returns_An_Empty_Record_For_An_Invalid_Session_Id

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${hmc_id}"}}

    ${records}=  Get Locks List  ${resp['Id']}
    ${records}=  Get Locks List  ZZzZZz9zzZ
    ${length}=  Get Length  ${records}
    Should Be Equal  ${length}  ${0}


Verify Lock Conflicts
    [Documentation]  Verify lock conflicts.
    [Tags]  Verify_Lock_Conflicts
    [Template]  Acquire And Release Lock

    Write  ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_OK}        ['NA']  ${True}
    Read   ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_CONFLICT}  ['NA']  ${False}
    Read   ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_OK}        ['NA']  ${True}
    Write  ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_CONFLICT}  ['NA']  ${False}
    Write  ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_OK}        ['NA']  ${True}
    Write  ${TWO_SEG_FLAG_2}  ${234}  hmc-id  ${HTTP_CONFLICT}  ['NA']  ${False}


Verify Persistency Of Read Locks After BMC Reboot
    [Documentation]  Verify persistency of locks after BMC reboot.
    [Tags]  Verify_Persistency_Of_Read_Locks_After_BMC_Reboot
    [Template]  Locks Persistency Check After BMC Reboot

    # lock_type  seg_flags          resource_id
    Read         ${TWO_SEG_FLAG_2}  ${234}


Verify Persistency Of Write Locks After BMC Reboot
    [Documentation]  Verify persistency of locks after BMC reboot.
    [Tags]  Verify_Persistency_Of_Write_Locks_After_BMC_Reboot
    [Template]  Locks Persistency Check After BMC Reboot

    # lock_type  seg_flags          resource_id
    Write        ${TWO_SEG_FLAG_2}  ${234}


Verify Valid Lock Transactions Release
    [Documentation]  Verify valid lock transactions release.
    [Tags]  Verify_Valid_Lock_Transactions_Release

    ${transaction_id1}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_2}  ${234}
    ${locks_before}=  Get Locks List  ${SESSION_ID}

    ${transaction_id2}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_3}  ${234}
    ${transaction_id3}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_2}  ${234}
    ${transaction_id4}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_3}  ${234}

    ${transaction_ids}=  Create List  ${transaction_id2}  ${transaction_id3}  ${transaction_id4}
    Release Locks  ${transaction_ids}
    ${locks_after}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${locks_before}  ${locks_after}


Verify Invalid Lock Transactions Release
    [Documentation]  Verify invalid lock transactions release.
    [Tags]  Verify_Invalid_Lock_Transactions_Release

    ${transaction_id1}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_2}  ${234}
    ${locks_before}=  Get Locks List  ${SESSION_ID}

    ${transaction_id2}=  Evaluate  ${transaction_id1} + 1
    ${transaction_id3}=  Evaluate  ${transaction_id1} - 1
    ${transaction_ids}=  Create List  ${transaction_id2}  ${transaction_id1}  ${transaction_id3}

    # If any transaction/s in the list does not belong to current session then it will be a bad request.
    Release Locks  ${transaction_ids}  exp_status_code=${HTTP_BAD_REQUEST}
    ${locks_after}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${locks_before}  ${locks_after}


Verify Locks Release By Session
    [Documentation]  Verify locks release by session.
    [Tags]  Verify_Locks_Release_By_Session

    ${locks_before}=  Get Locks List  ${SESSION_ID}
    ${transaction_id1}=  Acquire Lock On A Given Resource  Write  ${TWO_SEG_FLAG_2}  ${234}

    # Release Lock by Session without mentioning transaction_ids.
    Release Locks  release_type=Session
    ${locks_after}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${locks_before}  ${locks_after}

    ${transaction_id1}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_2}  ${234}
    ${transaction_id2}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_3}  ${234}
    ${transaction_ids}=  Create List  ${transaction_id1}  ${transaction_id2}

    # Release Lock by Session by mentioning transaction_ids also in the request.
    Release Locks  ${transaction_ids}  release_type=Session


Verify Locks Created By One Session Cannot Be Deleted By Another Session
    [Documentation]  Verify locks created by one session cannot be deleted by another session.
    [Tags]  Verify_Locks_Created_By_One_Session_Cannot_Be_Deleted_By_Another_Session
    [Setup]  No Operation

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"hmc-id"}}
    Set Test Variable  ${SESSION_ID}  ${resp['Id']}
    ${transaction_id1}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_2}  ${234}
    ${locks_tran1}=  Get Locks List  ${resp['Id']}

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"hmc-id"}}
    Set Test Variable  ${SESSION_ID}  ${resp['Id']}

    ${transaction_id2}=  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_3}  ${234}
    ${locks_before}=  Get Locks List  ${resp['Id']}

    ${transaction_ids}=  Create List  ${transaction_id1}  ${transaction_id2}
    Release Locks  ${transaction_ids}  exp_status_code=${HTTP_UNAUTHORIZED}  conflict_record=${locks_tran1}
    ${locks_after}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${locks_before}  ${locks_after}

    # When release_type=Session, transaction_ids should be ignored.
    Release Locks  ${transaction_ids}  release_type=Session
    ${locks_after}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${EMPTY_LIST}  ${locks_after}


*** Keywords ***

Locks Persistency Check After BMC Reboot
    [Documentation]  Locks persistency check after BMC reboot.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}

    # Description of argument(s):
    # lock_type    Type of lock (Read/Write).
    # seg_flags    Segmentation Flags to identify lock elements under system level in the hierarchy.
    # resource_id  Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.

    ${transaction_id}=  Acquire Lock On A Given Resource  ${lock_type}  ${seg_flags}  ${resource_id}

    ${locks_prev}=  Get Locks List  ${SESSION_ID}

    Redfish OBMC Reboot (off)
    Redfish Login

    ${locks_curr}=  Get Locks List  ${SESSION_ID}
    Should Be Equal  ${locks_prev}  ${locks_curr}

    ${transaction_ids}=  Create List  ${transaction_id}
    Release Locks  ${transaction_ids}


Return Data Dictionary For Single Request
    [Documentation]  Return data dictionary for single request.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}

    # Description of argument(s):
    # lock_type    Type of lock (Read/Write).
    # seg_flags    Segmentation Flags to identify lock elements under system level in the hierarchy.
    # resource_id  Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.

    ${SEG_FLAGS_LOCK}=  Create Dictionary
    ...  LockType=${lock_type}
    ...  SegmentFlags=@{seg_flags}
    ...  ResourceID=${resource_id}

    ${SEG_FLAGS_ENTRIES}=  Create List  ${SEG_FLAGS_LOCK}
    ${LOCK_REQUEST}=  Create Dictionary  Request=${SEG_FLAGS_ENTRIES}
    Log To Console  \n${SPACE}${LOCK_REQUEST}

    [Return]  ${LOCK_REQUEST}


Acquire Lock On A Given Resource
    [Documentation]  Acquire lock on a given resource.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}  ${exp_status_code}=${HTTP_OK}
    ...  ${err_msgs}=${EMPTY_LIST}

    # Description of argument(s):
    # lock_type        Type of lock (Read/Write).
    # seg_flags        Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                  Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
    #                        {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id      Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # exp_status_code  Expected status code from the AcquireLock request for given inputs.
    # err_msgs         List of expected error messages.

    ${data}=  Return Data Dictionary For Single Request  ${lock_type}  ${seg_flags}  ${resource_id}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${data}

    ${transaction_id}=  Run Keyword If  ${exp_status_code} != ${HTTP_OK}
    ...      Set Variable  ${0}
    ...  ELSE
    ...     Load Lock Record And Build Transaction To Session Map  ${resp.text}

    Run Keyword If  ${exp_status_code} == ${HTTP_CONFLICT} and ${err_msgs} == ['NA']
    ...      Load Response And Verify Conflict  ${resp.text}  ${SESSION_ID}
    ...  ELSE  Run Keyword If  ${exp_status_code} != ${HTTP_OK} and ${err_msgs} != ${EMPTY_LIST}
    ...     Load Response And Verify Error  ${resp.text}  err_msgs=${err_msgs}

    Append Transaction Id And Session Id To Locks Dictionary  ${transaction_id}

    [Return]  ${transaction_id}


Load Lock Record And Build Transaction To Session Map
    [Documentation]  Load lock record and build transaction to session map.
    [Arguments]  ${resp_text}

    # Description of argument(s):
    # resp_text  Response test from a REST request.

    ${acquire_lock}=  Evaluate  json.loads('''${resp_text}''')  json
    Append Transaction Id And Session Id To Locks Dictionary  ${acquire_lock["TransactionID"]}

    [Return]  ${acquire_lock["TransactionID"]}


Load Response And Verify Error
    [Documentation]  Load response and verify error.
    [Arguments]  ${error_resp}  ${err_msgs}=${EMPTY_LIST}

    # Description of argument(s):
    # error_resp  Error response from a REST request.
    # err_msgs    List of error msg patterns.

    ${error_resp}=  Replace String  ${error_resp}  \"  \\"
    ${error_response}=  Evaluate  json.loads('''${error_resp}''')  json

    ${errors}=  Get Dictionary Values  ${error_response}
    ${extended_errors}=  Create List

    FOR  ${error}  IN  @{errors}
      Append To List  ${extended_errors}  ${error[0]["Message"]}
    END

    Log To Console  \n ${extended_errors}

    FOR  ${exp_error}  IN  @{err_msgs}
        Run Keyword  Expect List Of Errors In An Extended Errors  ${exp_error}  ${extended_errors}
    END


Expect List Of Errors In An Extended Errors
    [Documentation]  Expect list of errors in an extended errors.
    [Arguments]  ${exp_error}  ${extended_errors}=${EMPTY_LIST}

    ${found}=  Set Variable  ${False}

    FOR  ${error_record}  IN  @{extended_errors}
      ${found}=  Evaluate  '${exp_error}' in '${error_record}'
      Exit For Loop If  ${found} == ${True}
    END

    Should Be True  ${found}


Append Transaction Id And Session Id To Locks Dictionary
    [Documentation]  Append transaction id and session id to locks dictionary.
    [Arguments]  ${transaction_id}

    # Description of argument(s):
    # transaction_id  Transaction ID created from acquire lock request. Ex: 8, 9 etc.

    Set To Dictionary  ${LOCKS}  ${${transaction_id}}  ${session_id}


Get Locks List
    [Documentation]  Get locks list.
    [Arguments]  @{sessions}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # sessions         List of comma separated strings. Ex: ["euHoAQpvNe", "ecTjANqwFr"]
    # exp_status_code  expected status code from the GetLockList request for given inputs.

    ${sessions}=  Evaluate  json.dumps(${sessions})  json
    ${data}=  Set Variable  {"SessionIDs": ${sessions}}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  data=${data}
    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json

    [Return]  ${locks["Records"]}


Release Locks
    [Documentation]  Release locks.
    [Arguments]  ${transaction_ids}=${EMPTY_LIST}  ${release_type}=Transaction  ${exp_status_code}=${HTTP_OK}
    ...  ${conflict_record}=${EMPTY_LIST}

    # Description of argument(s):
    # transaction_ids  List of transaction ids or session ids. Ex: [15, 18]  or ["euHoAQpvNe", "ecTjANqwFr"]
    # release_type     Release all locks acquired using current session or only given transaction numbers.
    #                  Ex:  Session,  Transaction.  Default will be Transaction.
    # exp_status_code  expected status code from the ReleaseLock request for given inputs.
    # conflict_record  Expected conflict record.

    # When release_type=Session then TransactionIDs list will be ignored.
    ${data}=  Set Variable  {"Type": "${release_type}", "TransactionIDs": ${transaction_ids}}
    ${data}=  Evaluate  json.dumps(${data})  json
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.ReleaseLock  data=${data}
    Should Be True  ${resp.status_code}  ${exp_status_code}
    Return From Keyword If  ${conflict_record} == ${EMPTY_LIST}

    ${conflict}=  Evaluate  json.loads('''${resp.text}''')  json

    # Example of conflict
    # {
    #    "Record":{
    #       "HMCID":"hmc-id",
    #       "LockType":"Read",
    #       "ResourceID":234,
    #       "SegmentFlags":[
    #          {
    #             "LockFlag":"DontLock",
    #             "SegmentLength":3
    #          },
    #          {
    #             "LockFlag":"LockAll",
    #             "SegmentLength":1
    #          }
    #       ],
    #       "SessionID":"OorUVwrXuT",
    #       "TransactionID":47
    #    }
    # }

    Should Be Equal  ${conflict_record[0]}  ${conflict["Record"]}


Verify Lock Record
    [Documentation]  Verify lock record.
    [Arguments]  ${lock_found}  &{lock_records}

    # Description of argument(s):
    # lock_found    True if lock record is expected to be present, else False.
    # lock_records  A dictionary containing key value pairs of a lock record.

    ${session}=  Get From Dictionary  ${LOCKS}  ${lock_records["TransactionID"]}
    ${locks}=  Get Locks List  ${session}

    ${lock_record_found}=  Set Variable  ${False}

    FOR  ${record}  IN  @{locks}
      ${record}=  Evaluate  json.dumps(${record})  json
      ${record}=  Evaluate  json.loads('''${record}''')  json
      ${lock_record_found}=  Set Variable If  ${record["TransactionID"]} == ${lock_records["TransactionID"]}
      ...  ${True}  ${False}

      Continue For Loop If  ${lock_record_found} == ${False}
      Dictionaries Should Be Equal  ${record}  ${lock_records}
      Exit For Loop
    END

    Should Be Equal  ${lock_record_found}  ${lock_found}


Load Response And Verify Conflict
    [Documentation]  Load response and verify conflict.
    [Arguments]  ${conflict_resp}  ${sessions}

    # Description of argument(s):
    # conflict_resp  Conflict response from a REST request.
    #                Example : { "Record": { "HMCID": "hmc-id", "LockType": "Write", "ResourceID": 234,
    #                            "SegmentFlags": [ { "LockFlag": "DontLock", "SegmentLength": 3},
    #                                              { "LockFlag": "LockAll",  "SegmentLength": 1}],
    #                            "SessionID": "B6geYEdo6T", "TransactionID": 104 } }
    # sessions       Comma separated list of sessions

    ${curr_locks}=  Get Locks List  ${sessions}
    ${conflict_resp}=  Replace String  ${conflict_resp}  \"  \\"
    ${conflict_response}=  Evaluate  json.loads('''${conflict_resp}''')  json

    ${conflicts}=  Get Dictionary Values  ${conflict_response}
    List Should Contain Value  ${conflicts}  ${PREV_INPUTS}


Acquire And Release Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}  ${hmc_id}  ${exp_status_code}=${HTTP_OK}
    ...  ${err_msgs}=${EMPTY_LIST}  ${new_sess_req}=${True}

    # Description of argument(s):
    # lock_type        Type of lock (Read/Write).
    # seg_flags        Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                  Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
    #                        {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id      Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # hmc_id           Hardware management console id.
    # exp_status_code  Expected status code from the AcquireLock request for given inputs.
    # err_msgs         List of expected error messages.
    # new_sess_req     Create a new session before acquiring a lock if True.

    # Delete the session.
    Run Keyword If  ${new_sess_req} == ${True}  Run Keyword And Ignore Error  Delete All Redfish Sessions

    # Get REST session to BMC.
    Run Keyword If  ${new_sess_req} == ${True}  Create New Session

    ${inputs}=  Create Dictionary
    ...  LockType=${lock_type}
    ...  ResourceID=${resource_id}
    ...  SegmentFlags=${seg_flags}
    ...  HMCID=${hmc_id}

    ${transaction_id}=  Acquire Lock On A Given Resource  ${inputs["LockType"]}
    ...  ${inputs["SegmentFlags"]}  ${inputs["ResourceID"]}  ${exp_status_code}  err_msgs=${err_msgs}

    # Each lock request from a new session is saved so that for next lock request using same session
    # can refer to previous lock data to verify conflict records if any.
    Run Keyword If  ${new_sess_req} == ${True}  Set Test Variable Dictionary Of Previous Lock Request
    ...  ${lock_type}  ${seg_flags}  ${resource_id}  ${hmc_id}  ${SESSION_ID}  ${transaction_id}

    ${session}=  Get From Dictionary  ${LOCKS}  ${transaction_id}
    Set To Dictionary  ${inputs}  TransactionID=${${transaction_id}}  SessionID=${session}

    ${lock_found}=  Set Variable If  ${exp_status_code} == ${HTTP_OK}  ${True}  ${False}
    Verify Lock Record  ${lock_found}  &{inputs}

    Return From Keyword If  '${exp_status_code}' != '${HTTP_OK}' or ${err_msgs} == ['NA']
    ${transaction_ids}=  Create List  ${transaction_id}
    Release Locks  ${transaction_ids}
    Verify Lock Record  ${False}  &{inputs}


Create New Session
    [Documentation]  Create new session.

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${hmc_id}"}}
    Set Test Variable  ${SESSION_ID}  ${resp['Id']}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Run Keyword And Ignore Error  Delete All Redfish Sessions


Return Session Id And Session Key
    [Documentation]  Return session id and sesion key.

    ${session_location}=  Redfish.Get Session Location
    ${session_id}=  Evaluate  os.path.basename($session_location)  modules=os
    ${session_key}=  Redfish.Get Session Key

    [Return]  ${session_id}  ${session_key}


Test Setup Execution
    [Documentation]  Test setup execution.

    # This is a test constant value.
    Set Test Variable  ${hmc_id}  hmc-id
    Create New Session

    Set Test Variable Dictionary Of Previous Lock Request
    ...  ${EMPTY}  ${EMPTY_LIST}  ${EMPTY}  ${EMPTY}  ${EMPTY}  ${EMPTY}


Set Test Variable Dictionary Of Previous Lock Request
    [Documentation]  Set test variable dictionary of previous lock request.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}  ${hmc_id}  ${session_id}  ${transaction_id}

    # Description of argument(s):
    # lock_type            Type of lock (Read/Write).
    # seg_flags            Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                      Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
    #                           {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id          Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # hmc_id               Hardware management console id.
    # session_id           Session id of the transaction.
    # transaction_id       Transaction_id of the lock request.

    ${prev_inputs}=  Create Dictionary
    ...  LockType=${lock_type}
    ...  ResourceID=${resource_id}
    ...  SegmentFlags=${seg_flags}
    ...  HMCID=${hmc_id}
    ...  SessionID=${session_id}
    ...  TransactionID=${transaction_id}

    Set Test Variable  ${PREV_INPUTS}  ${prev_inputs}
