#!/usr/bin/env bash

###############################################################################
# This script performs the same task as "e_demo.sh" but demonstrates a major
# performance-optimization technique for shellfloat. The speedup is especially
# significant when run on a Linux emulation layer such as Cygwin or minGW over
# a Windows substrate.
#
# The speedup relies on a hidden mechanism to simulate pass-and-return by
# reference, eliminating the need for echos and subshells in order to capture
# the side effects of a function call. See the code for examples but basically, 
# if you start by turning off "__shellfloat_isVerbose" (see below),
#    then the line   "value = $(myFunction argument)"
#    can become      "myFunction argument;  _shellfloat_getReturnValue value".
###############################################################################

source shellfloat.sh

if [[ $# -ne 1 ]]; then
    echo "USAGE: ${BASH_SOURCE##*/}  *N*"
    echo "       Approximates 'e' using the N-th order Maclaurin polynomial"
    echo "       (i.e. the Taylor polynomial centered at 0)."
    exit 0
elif [[ ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Illegal argument. Whole numbers only, please."
    exit 1
fi

__shellfloat_isVerbose=${__shellfloat_false}

# Initialize
n=0;  N=$1;  zero_factorial=1

# Initialize "e" to its zeroth-order term
_shellfloat_divide  1  $zero_factorial
_shellfloat_getReturnValue term
e=$term

# Compute successive terms T(n) := T(n-1)/n and accumulate into e
for ((n=1; n<=N; n++)); do
    _shellfloat_divide  $term  $n
    _shellfloat_getReturnValue term
    _shellfloat_add  $e  $term
    _shellfloat_getReturnValue e
done

echo "e = $e"
exit 0
