#!/usr/bin/env bash

source shellfloat.sh

if [[ $# -ne 1 ]]; then
    echo "USAGE: $0  _N_"
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

# Initialize e to the zeroth-order term
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
