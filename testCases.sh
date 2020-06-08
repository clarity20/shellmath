#!/usr/bin/env bash

################################################################
# The general testcase syntax is 
#    asserter  expectation   functionUnderTest [args ... ]
#
# where asserter is either of:
#    Code      to indicate decimal return code
#    String    to indicate the string generated as a side effect
#
# and functionUnderTest is the function name
# with the "_shellfloat_" prefix removed.
################################################################

# Tests for getReturnCode()
Code 0   getReturnCode SUCCESS
Code 1   getReturnCode FAIL

# Tests for warn()
String "Invalid decimal number argument: '2.qr'"  \
    warn "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}" 2.qr


