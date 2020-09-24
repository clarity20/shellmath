################################################################################
# shellfloat.sh
# Shell functions for floating-point arithmetic using only builtins
#
# Copyright (c) 2020 by Michael Wood. All rights reserved.
#
# Usage:
#
#    source thisPath/shellfloat.sh
#    add() { echo $(_shellfloat_add "$@"); }    # Rename as desired
#    mySum=$(add 202.895 6.00311)
# 
################################################################################

declare -A -r __shellfloat_returnCodes=(
    [SUCCESS]="0:Success"
    [FAIL]="1:General failure"
    [ILLEGAL_NUMBER]="2:Invalid decimal number argument: '%s'"
)

declare -A -r __shellfloat_numericTypes=(
    [INTEGER]=64
    [DECIMAL]=32
    [SCIENTIFIC]=16
)
declare -r __shellfloat_allTypes=$((__shellfloat_numericTypes[INTEGER] \
    + __shellfloat_numericTypes[DECIMAL] \
    + __shellfloat_numericTypes[SCIENTIFIC]))

declare -r __shellfloat_true=1
declare -r __shellfloat_false=0

function _shellfloat_getReturnCode()
{
    local errorName="$1"
    return ${__shellfloat_returnCodes[$errorName]%%:*}
}

function _shellfloat_warn()
{
    # Generate an error message and return control to the caller
    _shellfloat_handleError -r "$@"
    return $?
}

function _shellfloat_exit()
{
    # Generate an error message and EXIT THE SCRIPT / interpreter
    _shellfloat_handleError "$@"
}

function _shellfloat_handleError()
{
    # Hidden option "-r" causes return instead of exit
    if [[ "$1" == "-r" ]]; then
        returnDontExit=${__shellfloat_true}
        shift
    fi

    # Format of $1:  returnCode:msgTemplate
    [[ "$1" =~ ^([0-9]+):(.*) ]]
    returnCode=${BASH_REMATCH[1]}
    msgTemplate=${BASH_REMATCH[2]}
    shift
    
    # Display error msg, making parameter substitutions as needed
    msgParameters="$@"
    printf  "$msgTemplate" "${msgParameters[@]}"

    if [[ $returnDontExit == ${__shellfloat_true} ]]; then
        return $returnCode
    else
        exit $returnCode
    fi

}


################################################################################
# Simulate pass-and-return by reference using a secret global storage array
################################################################################

declare -a __shellfloat_storage
declare -ir __shellfloat_storageSpace=8

function _shellfloat_setReturnValues()
{
    declare -i _i
    local _givenValue _storageCell

    for ((_i=1; _i<=$#; _i++)); do
        _storageCell="__shellfloat_storage["$_i"]"
        _givenValue=${!_i}
        eval $_storageCell='$_givenValue'
    done
    for ((; _i<=__shellfloat_storageSpace; _i++)); do
        unset __shellfloat_storage[$_i]
    done
}

function _shellfloat_getReturnValues()
{
    declare -i _i
    local _variableName _valueInStorage _storageCell

    for ((_i=1; _i<=$#; _i++)); do
        _variableName=${!_i}
        _storageCell="__shellfloat_storage["$_i"]"
        _valueInStorage=${!_storageCell}
        if [[ -n $_valueInStorage ]]; then
            eval $_variableName='$_valueInStorage'
        else
            unset $_variableName
        fi
    done
}

function _shellfloat_setReturnValue() { _shellfloat_setReturnValues "$1"; }
function _shellfloat_getReturnValue() { _shellfloat_getReturnValues "$1"; }


################################################################################
# Validate and parse arguments to the main arithmetic routines
################################################################################

function _shellfloat_validateAndParse()
{
    local n="$1"
    local isNegative=${__shellfloat_false}
    local numericType

    # Initialize return code to SUCCESS
    _shellfloat_getReturnCode SUCCESS
    local returnCode=$?
    
    # Accept integers
    if [[ "$n" =~ ^[-]?[0-9]+$ ]]; then
        numericType=${__shellfloat_numericTypes[INTEGER]}

        # Factor out the negative sign if it is present
        if [[ "$n" =~ ^- ]]; then
            isNegative=${__shellfloat_true}
            n=${n:1}
        fi

        _shellfloat_setReturnValues $n 0
        return $((numericType|isNegative))

    # Accept decimals: leading digits (optional), decimal point, trailing digits
    elif [[ "$n" =~ ^[-]?([0-9]*)\.([0-9]+)$ ]]; then
        local integerPart=${BASH_REMATCH[1]:-0}
        local fractionalPart=${BASH_REMATCH[2]}
        numericType=${__shellfloat_numericTypes[DECIMAL]}

        # Factor out the negative sign if it is present
        if [[ "$n" =~ ^- ]]; then
            isNegative=${__shellfloat_true}
            n=${n:1}
        fi

        _shellfloat_setReturnValues $integerPart $fractionalPart
        return $((numericType|isNegative))

    # Accept scientific notation: 1e5, 2.44E+10, etc.
    elif [[ "$n" =~ (.*)[Ee](.*) ]]; then
        local significand=${BASH_REMATCH[1]}
        local exponent=${BASH_REMATCH[2]}

        # Validate the significand: optional sign, integer part,
        # optional decimal point and fractional part
        if [[ "$significand" =~ ^[-]?([0-9]+)(\.([0-9]+))?$ ]]; then

            # Separate the integer and fractional parts
            local sigInteger=${BASH_REMATCH[1]}
            local sigIntLength=${#sigInteger}
            local sigFraction=${BASH_REMATCH[3]}
            local sigFracLength=${#sigFraction}

            if [[ "$n" =~ ^- ]]; then
                isNegative=${__shellfloat_true}
                n=${n:1}
            fi

            # Rewrite the scientifically-notated number in ordinary decimal notation.
            # IOW, realign the integer and fractional parts. Separate with a space
            # so they can be returned as two separate values
            if ((exponent > 0)); then
                ((zeroCount = exponent - sigFracLength))
                if ((zeroCount > 0)); then
                    printf -v zeros "%0*s" $zeroCount 0
                    n=${sigInteger}${sigFraction}${zeros}
                    numericType=${__shellfloat_numericTypes[INTEGER]}
                elif ((zeroCount < 0)); then
                    n=${sigInteger}${sigFraction:0:exponent}" "${sigFraction:exponent}
                    numericType=${__shellfloat_numericTypes[DECIMAL]}
                else
                    n=${sigInteger}${sigFraction}
                    numericType=${__shellfloat_numericTypes[INTEGER]}
                fi
                _shellfloat_setReturnValues ${n}
                return $((numericType|isNegative))

            elif ((exponent < 0)); then
                ((zeroCount = -exponent - sigIntLength))
                if ((zeroCount > 0)); then
                    printf -v zeros "%0*s" $zeroCount 0
                    n="0 "${zeros}${sigInteger}${sigFraction}
                    numericType=${__shellfloat_numericTypes[DECIMAL]}
                elif ((zeroCount < 0)); then
                    n=${sigInteger:0:-zeroCount}" "${sigInteger:(-zeroCount)}${sigFraction}
                    numericType=${__shellfloat_numericTypes[DECIMAL]}
                else
                    n="0 "${sigInteger}${sigFraction}
                    numericType=${__shellfloat_numericTypes[DECIMAL]}
                fi
                _shellfloat_setReturnValues ${n}
                return $((numericType|isNegative))

            else
                # exponent == 0 means the number is already aligned as desired
                n=${sigInteger}" "${sigFraction}
                _shellfloat_setReturnValues ${n}
                numericType=${__shellfloat_numericTypes[DECIMAL]}
                return $((numericType|isNegative))
            fi

        # Reject "pseudo-scientific numbers" xxx[Ee]yyy where xxx, yyy are invalid as numbers
        else
            _shellfloat_getReturnCode ILLEGAL_NUMBER
            returnCode=$?
            _shellfloat_setReturnValues ""
            return $returnCode
        fi

    # Reject everything else
    else
        _shellfloat_getReturnCode ILLEGAL_NUMBER
        returnCode=$?
        _shellfloat_setReturnValues ""
        return $returnCode
    fi
}


function _shellfloat_checkArgument()
{
    local arg="$1"
    local integerPart fractionalPart
    local flags isNegative type

    _shellfloat_getReturnCode "ILLEGAL_NUMBER"
    declare -ri ILLEGAL_NUMBER=$?

    _shellfloat_validateAndParse "$arg";  flags=$?
    _shellfloat_getReturnValues  integerPart  fractionalPart

    if [[ "$flags" == "$ILLEGAL_NUMBER" ]]; then
        _shellfloat_warn  ${__shellfloat_returnCodes[ILLEGAL_NUMBER]}  "$arg"
        return $?
    fi

    # Register important information about the first value
    isNegative=$((flags & __shellfloat_true))
    type=$((flags & __shellfloat_allTypes))

    _shellfloat_setReturnValues "$integerPart" "$fractionalPart" $isNegative $type
    return $SUCCESS
}

################################################################################
# The main arithmetic routines
################################################################################

function _shellfloat_add()
{
    local n1="$1"
    local n2="$2"
    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isNegative2 type2

    # Set constants
    _shellfloat_getReturnCode "SUCCESS"
    declare -ri SUCCESS=$?
    local isTesting=$(( __shellfloat_isTesting == __shellfloat_true ))
    local isSubcall=${__shellfloat_false}       # Is the caller itself an arithmetic function?
    [[ "${FUNCNAME[1]}" =~ _(add|subtract|multiply|divide)$ ]] && (( isSubcall = __shellfloat_true ))

    # Handle corner cases where argument count is not 2
    if [[ $# -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  addend_1  addend_2"
        return $SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the result as-is, print if running "normally", and return
        _shellfloat_setReturnValue $n1
        if (( !(isTesting || isSubcall) )); then echo $n1; fi
        return $SUCCESS
    elif [[ $# -gt 2 ]]; then
        # Recurse on the trailing arguments
        shift
        _shellfloat_add "$@"
        local recursiveReturn=$?
        _shellfloat_getReturnValue n2       # use n2 as an accumulator
        if [[ "$recursiveReturn" != "$SUCCESS" ]]; then
            _shellfloat_setReturnValue $n2
            return $recursiveReturn
        fi
    fi

    # Check and break down the first argument
    _shellfloat_checkArgument "$n1"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart1 fractionalPart1 isNegative1 type1

    # Check and break down the second argument
    _shellfloat_checkArgument "$n2"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart2 fractionalPart2 isNegative2 type2

    # Quick add & return for integer adds
    if ((type1==type2 && type1==__shellfloat_numericTypes[INTEGER])); then
        local sum=$((integerPart1 + integerPart2))
        _shellfloat_setReturnValue $sum
        if ((! (isTesting || isSubcall) )); then
            echo $sum
        fi

        return $SUCCESS
    fi

    # Right-pad both fractional parts with zeros to the same length
    declare fractionalLen1=${#fractionalPart1}
    declare fractionalLen2=${#fractionalPart2}
    if ((fractionalLen1 > fractionalLen2)); then
        # Use printf to zero-pad. This avoids mathematical side effects.
        printf -v fractionalPart2 %-*s $fractionalLen1 $fractionalPart2
        fractionalPart2=${fractionalPart2// /0}
    elif ((fractionalLen2 > fractionalLen1)); then
        printf -v fractionalPart1 %-*s $fractionalLen2 $fractionalPart1
        fractionalPart1=${fractionalPart1// /0}
    fi
    declare unsignedFracLength=${#fractionalPart1}

    # Implement a sign convention that will enable us to detect carries by
    # comparing string lengths of addends and sums: propagate the sign across
    # both numeric parts (whether unsigned or zero).
    if ((isNegative1)); then
        fractionalPart1="-"$fractionalPart1
        integerPart1="-"$integerPart1
    fi
    if ((isNegative2)); then
        fractionalPart2="-"$fractionalPart2
        integerPart2="-"$integerPart2
    fi

    declare integerSum=0      # To allow string manipulation, do not declare "-i"
    declare fractionalSum=0

    ((integerSum = integerPart1+integerPart2))

    # Summing the fractional parts is tricky: We need to override the shell's
    # default interpretation of leading zeros, but the operator for doing this
    # (the "10#" operator) cannot work directly with negative numbers. So we
    # break it all down.
    if ((isNegative1)); then
        ((fractionalSum += (-1) * 10#${fractionalPart1:1}))
    else
        ((fractionalSum += 10#$fractionalPart1))
    fi
    if ((isNegative2)); then
        ((fractionalSum += (-1) * 10#${fractionalPart2:1}))
    else
        ((fractionalSum += 10#$fractionalPart2))
    fi

    unsignedFracSumLength=${#fractionalSum}
    if [[ "$fractionalSum" =~ ^[-] ]]; then
        ((unsignedFracSumLength--))
    fi

    # Restore any leading zeroes that were lost when adding
    if ((unsignedFracSumLength < unsignedFracLength)); then
        local lengthDiff=$((unsignedFracLength - unsignedFracSumLength))
        local zeroPrefix
        printf -v zeroPrefix "%0*s" $lengthDiff 0
        if ((fractionalSum < 0)); then
            fractionalSum="-"${zeroPrefix}${fractionalSum:1}
        else
            fractionalSum=${zeroPrefix}${fractionalSum}
        fi
    fi

    # Carry a digit from fraction to integer if required
    if ((fractionalSum!=0 && unsignedFracSumLength > unsignedFracLength)); then
        local carryAmount
        ((carryAmount=isNegative1?-1:1))
        ((integerSum += carryAmount))
        # Remove the leading 1-digit whether the fraction is + or -
        fractionalSum=${fractionalSum/1/}
    fi

    # Resolve sign discrepancies between the partial sums
    if ((integerSum < 0 && fractionalSum > 0)); then
        ((integerSum += 1))
        ((fractionalSum = 10**unsignedFracSumLength - fractionalSum))
    elif ((integerSum > 0 && fractionalSum < 0)); then
        ((integerSum -= 1))
        ((fractionalSum = 10**unsignedFracSumLength + fractionalSum))
    elif ((integerSum == 0 && fractionalSum < 0)); then
        integerSum="-"$integerSum
        ((fractionalSum *= -1))
    fi

    # Touch up the numbers for display
    local sum
    if ((fractionalSum < 0)); then fractionalSum=${fractionalSum:1}; fi
    if ((fractionalSum)); then
        printf -v sum "%s.%s" $integerSum $fractionalSum
    else
        sum=$integerSum
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $sum
    if ((! (isTesting || isSubcall) )); then
        echo $sum
    fi

    return $SUCCESS
}

################################################################################

function _shellfloat_subtract()
{
    local n1="$1"
    local n2="$2"
    local isTesting=$(( __shellfloat_isTesting == __shellfloat_true ))

    if [[ $# -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  subtrahend  minuend"
        return $SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue $n1
        if ((!isTesting)); then echo $n1; fi
        return $SUCCESS
    fi

    # Symbolically negate the second argument
    if [[ $n2 =~ ^- ]]; then
        n2=${n2:1}
    else
        n2="-"$n2
    fi

    # Note the result, print if running "normally", and return
    local difference
    _shellfloat_add "$n1" "$n2"
    _shellfloat_getReturnValue difference
    if ((!isTesting)); then
        echo $difference
    fi

    return $?
}

################################################################################

function _shellfloat_multiply()
{
    local n1="$1"
    local n2="$2"
    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isNegative2 type2

    # Set constants
    _shellfloat_getReturnCode "SUCCESS"
    declare -ri SUCCESS=$?
    local isTesting=$(( __shellfloat_isTesting == __shellfloat_true ))

    # Handle corner cases where argument count is not 2
    if [[ $# -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  factor_1  factor_2"
        return $SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue $n1
        if ((!isTesting)); then echo $n1; fi
        return $SUCCESS
    elif [[ $# -gt 2 ]]; then
        # Recurse on the trailing arguments
        shift
        _shellfloat_multiply "$@"
        local recursiveReturn=$?
        _shellfloat_getReturnValue n2       # use n2 as an accumulator
        if [[ "$recursiveReturn" != "$SUCCESS" ]]; then
            _shellfloat_setReturnValue $n2
            return $recursiveReturn
        fi
    fi

    # Check and break down the first argument
    _shellfloat_checkArgument "$n1"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart1 fractionalPart1 isNegative1 type1

    # Check and break down the second argument
    _shellfloat_checkArgument "$n2"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart2 fractionalPart2 isNegative2 type2

    # Declarations: four components of the product per the distributive law
    declare intProduct floatProduct innerProduct1 innerProduct2
    # Widths of the decimal parts
    declare floatWidth fractionalWidth1 fractionalWidth2

    # Compute the integer and floating-point components
    ((intProduct = integerPart1 * integerPart2))
    fractionalWidth1=${#fractionalPart1}
    fractionalWidth2=${#fractionalPart2}
    ((floatWidth = fractionalWidth1 + fractionalWidth2))
    ((floatProduct = 10#$fractionalPart1 * 10#$fractionalPart2))
    if ((${#floatProduct} < floatWidth)); then
        printf -v floatProduct "%0*s" $floatWidth $floatProduct
    fi

    # Compute the inner products: First integer-multiply, then rescale
    ((innerProduct1 = integerPart1 * 10#$fractionalPart2))
    ((innerProduct2 = integerPart2 * 10#$fractionalPart1))

    # Rescale the inner products as decimals so we can shellfloat_add() them
    if ((fractionalWidth2 <= ${#innerProduct1})); then
        local innerInt1=${innerProduct1:0:(-$fractionalWidth2)}
        local innerFloat1=${innerProduct1:(-$fractionalWidth2)}
        innerProduct1=${innerInt1}"."${innerFloat1}
    else
        printf -v innerProduct1 "0.%0*s" $fractionalWidth2 $innerProduct1
    fi
    if ((fractionalWidth1 <= ${#innerProduct2})); then
        local innerInt2=${innerProduct2:0:(-$fractionalWidth1)}
        local innerFloat2=${innerProduct2:(-$fractionalWidth1)}
        innerProduct2=${innerInt2}"."${innerFloat2}
    else
        printf -v innerProduct2 "0.%0*s" $fractionalWidth1 $innerProduct2
    fi

    # Combine the distributed parts
    local innerSum outerSum product
    _shellfloat_add  $innerProduct1  $innerProduct2
    _shellfloat_getReturnValue innerSum
    outerSum=${intProduct}"."${floatProduct}
    _shellfloat_add  $innerSum  $outerSum
    _shellfloat_getReturnValue product

    # Determine the sign of the product
    if ((isNegative1 != isNegative2)); then
        product="-"$product
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $product
    if ((!isTesting)); then
        echo $product
    fi

    return $SUCCESS
}

################################################################################

function _shellfloat_divide()
{
    local n1="$1"
    local n2="$2"
    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isNegative2 type2

    # Set constants
    _shellfloat_getReturnCode "SUCCESS"
    declare -ri SUCCESS=$?
    local isTesting=$(( __shellfloat_isTesting == __shellfloat_true ))

    if [[ $# -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  dividend  divisor"
        return $SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue $n1
        if ((!isTesting)); then echo $n1; fi
        return $SUCCESS
    fi

#TODO Throw error on divide by zero !!!

    # Check and break down the first argument
    _shellfloat_checkArgument "$n1"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart1 fractionalPart1 isNegative1 type1

    # Check and break down the second argument
    _shellfloat_checkArgument "$n2"
    if [[ $? == ${__shellfloat_returnCodes[ILLEGAL_NUMBER]} ]]; then return $?; fi
    _shellfloat_getReturnValues integerPart2 fractionalPart2 isNegative2 type2

    # Calculate with as much precision as the system will allow. To determine
    # this precision, we probe for the value at which long-long-ints overflow.
    # We test the 64-bit, 32-bit and 16-bit thresholds and set the precision
    # so as to keep us safely below the applicable threshold
    local precision
    if ((2**63 < 2**63-1)); then
        precision=18
    elif ((2**31 < 2**31-1)); then
        precision=9
    else     ## ((2**15 < 2**15-1))
        precision=4
    fi

    # Convert the division problem to an *integer* division problem by rescaling
    # both inputs so as to lose their decimal points. To obtain maximal precision,
    # we scale up the numerator further, padding with as many zeros as it can hold
    local numerator denominator quotient
    local rescaleFactor zeroCount zeroTail
    ((zeroCount = precision - ${#integerPart1} - ${#fractionalPart1}))
    ((rescaleFactor = precision - ${#integerPart1} - ${#fractionalPart2}))
    printf -v zeroTail "%0*s" $zeroCount 0

    # Rewrite the fraction to be computed, and compute it
    numerator=${integerPart1}${fractionalPart1}${zeroTail}
    denominator=${integerPart2}${fractionalPart2}
    quotient=((10#$numerator / 10#$denominator))

    # Rescale back
    quotient=${quotient:0:(-$rescaleFactor)}"."${quotient:(-$rescaleFactor)}

    # Determine the sign of the product
    if ((isNegative1 != isNegative2)); then
        quotient="-"$quotient
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $quotient
    if ((!isTesting)); then
        echo $quotient
    fi

    return $SUCCESS
}

