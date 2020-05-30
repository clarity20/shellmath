#!/usr/bin/env bash

source shellfloat.sh
source assert.sh

#################################################
# The general testcase syntax is 
#    asserter  expectation   functionCall [args ... ]
#################################################

# Tests for getReturnCode()
_shellfloat_assert_returnCode 0   _shellfloat_getReturnCode SUCCESS
_shellfloat_assert_returnCode 1   _shellfloat_getReturnCode FAIL

# Tests for _shellfloat_warn()
_shellfloat_assert_returnString "Invalid decimal number argument: '2.qr'"  \
    _shellfloat_warn "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}" 2.qr


