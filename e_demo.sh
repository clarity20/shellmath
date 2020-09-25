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

# Initialize
n=0;  N=$1;  zero_factorial=1

# Initialize e to the zeroth-order term
term=$(_shellfloat_divide  1  $zero_factorial)
e=$term

# Compute successive terms T(n) := T(n-1)/n and accumulate into e
for ((count=1; count<=N; count++)); do
    term=$(_shellfloat_divide  $term  $count)
    e=$(_shellfloat_add  $e  $term)
done

echo "e = $e"
# exit 0
