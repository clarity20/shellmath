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


