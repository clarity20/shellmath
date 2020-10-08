#!/usr/bin/env bash

###############################################################################
# This script illustrates the use of the shellfloat APIs to perform
# floating-point calculations. Here we approximate the mathematical constant 'e'
# using its Maclaurin polynomials (i.e. its Taylor polynomials centered at 0).
###############################################################################

source shellfloat.sh

# Setting the '-t' flag will cause the script to time the algorithm
if [[ "$1" -eq '-t' ]]; then
    do_timing=${__shellfloat_true}
    shift
fi

if [[ $# -ne 1 ]]; then
    echo "USAGE: ${BASH_SOURCE##*/}  [-t]  *N*"
    echo "       Approximates 'e' using the N-th order Maclaurin polynomial"
    echo "       (i.e. the Taylor polynomial centered at 0)."
    echo "       Specify the '-t' flag to time the main algorithm."
    exit 0
elif [[ ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Illegal argument. Whole numbers only, please."
    exit 1
fi


function run_algorithm()
{
    # Initialize
    n=0;  N=$1;  zero_factorial=1

    # Initialize e to the zeroth-order term
    term=$(_shellfloat_divide  1  $zero_factorial)
    e=$term

    # Compute successive terms T(n) := T(n-1)/n and accumulate into e
    for ((n=1; n<=N; n++)); do
        term=$(_shellfloat_divide  $term  $n)
        e=$(_shellfloat_add  $e  $term)
    done

    echo "e = $e"
}


if (( do_timing == __shellfloat_true )); then
    time run_algorithm "$1"
else
    run_algorithm "$1"
fi

exit 0

