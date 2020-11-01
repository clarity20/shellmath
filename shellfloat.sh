################################################################################
# shellfloat.sh
# Shell functions for floating-point arithmetic using only builtins
#
# Copyright (c) 2020 by Michael Wood. All rights reserved.
#
# Usage:
#
#    source  _thisPath_/_thisFileName_
#
#    # Conventional method: call the APIs by subshelling
#    mySum=$( _shellfloat_add 202.895 6.00311 )
#    echo $mySum
#
#    # Faster method: use hidden globals to simulate more flexible pass-and-return
#    _shellfloat_add 44.2 -87
#    _shellfloat_getReturnValue mySum
#    echo $mySum
# 
################################################################################


################################################################################
# Program constants
################################################################################
declare -A -r __shellfloat_numericTypes=(
    [INTEGER]=0
    [DECIMAL]=1
)

declare -A -r __shellfloat_returnCodes=(
    [SUCCESS]="0:Success"
    [FAIL]="1:General failure"
    [ILLEGAL_NUMBER]="2:Invalid argument; decimal number required: '%s'"
    [DIVIDE_BY_ZERO]="3:Divide by zero error"
)

declare -r __shellfloat_true=1
declare -r __shellfloat_false=0


################################################################################
# Program state
################################################################################
declare __shellfloat_isOptimized=${__shellfloat_false}
declare __shellfloat_didPrecalc=${__shellfloat_false}


################################################################################
# Error-handling utilities
################################################################################
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
# precalc()
#
# Pre-calculates certain global data and by setting the global variable
# "__shellfloat_didPrecalc" records that this routine has been called. As an
# optimization, the caller should check that global to prevent multiple
################################################################################
function _shellfloat_precalc()
{
    # Set a few global constants
    _shellfloat_getReturnCode SUCCESS; __shellfloat_SUCCESS=$?
    _shellfloat_getReturnCode FAIL; __shellfloat_FAIL=$?
    _shellfloat_getReturnCode ILLEGAL_NUMBER; __shellfloat_ILLEGAL_NUMBER=$?

    # Determine the decimal precision to which we can accurately calculate.
    # To do this we probe for the threshold at which integers overflow and
    # take the integer floor of that number's base-10 logarithm.
    # We check the 64-bit, 32-bit and 16-bit thresholds only.
    if ((2**63 < 2**63-1)); then
        __shellfloat_precision=18
    elif ((2**31 < 2**31-1)); then
        __shellfloat_precision=9
    else     ## ((2**15 < 2**15-1))
        __shellfloat_precision=4
    fi

    __shellfloat_didPrecalc=$__shellfloat_true
}


################################################################################
# Simulate pass-and-return by reference using a secret global storage array
################################################################################

declare -a __shellfloat_storage

function _shellfloat_setReturnValues()
{
    declare -i _i

    for ((_i=1; _i<=$#; _i++)); do
        __shellfloat_storage[_i]="${!_i}"
    done

    __shellfloat_storage[0]=$#
}

function _shellfloat_getReturnValues()
{
    declare -i _i
    local evalString

    for ((_i=1; _i<=$#; _i++)); do
        evalString+=${!_i}="${__shellfloat_storage[_i]}"" "
    done

    eval "$evalString"
}

function _shellfloat_setReturnValue() { __shellfloat_storage=(1 "$1"); }
function _shellfloat_getReturnValue() { eval "$1"=\"${__shellfloat_storage[1]}\"; }
function _shellfloat_getReturnValueCount() { eval "$1"=\"${__shellfloat_storage[0]}\"; }

################################################################################
# validateAndParse(numericString)
# Return Code:      SUCCESS or ILLEGAL_NUMBER
# Return Signature: integerPart fractionalPart isNegative numericType isScientific
#
# Validate and parse arguments to the main arithmetic routines
################################################################################

function _shellfloat_validateAndParse()
{
    local n="$1"
    local isNegative=${__shellfloat_false}
    local isScientific=${__shellfloat_false}
    local numericType returnCode

    ((returnCode = __shellfloat_SUCCESS))
    
    # Accept integers
    if [[ "$n" =~ ^[-]?[0-9]+$ ]]; then
        numericType=${__shellfloat_numericTypes[INTEGER]}

        # Factor out the negative sign if it is present
        if [[ "$n" =~ ^- ]]; then
            isNegative=${__shellfloat_true}
            n=${n:1}
        fi

        _shellfloat_setReturnValues $n 0 $isNegative $numericType $isScientific
        return $returnCode

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

        _shellfloat_setReturnValues $integerPart $fractionalPart \
                    $isNegative $numericType $isScientific
        return $returnCode

    # Accept scientific notation: 1e5, 2.44E+10, etc.
    elif [[ "$n" =~ (.*)[Ee](.*) ]]; then
        local significand=${BASH_REMATCH[1]}
        local exponent=${BASH_REMATCH[2]}

        # Validate the significand: optional sign, integer part,
        # optional decimal point and fractional part
        if [[ "$significand" =~ ^[-]?([0-9]+)(\.([0-9]+))?$ ]]; then

            isScientific=${__shellfloat_true}

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
                    n=${sigInteger}${sigFraction}${zeros}" 0"
                    numericType=${__shellfloat_numericTypes[INTEGER]}
                elif ((zeroCount < 0)); then
                    n=${sigInteger}${sigFraction:0:exponent}" "${sigFraction:exponent}
                    numericType=${__shellfloat_numericTypes[DECIMAL]}
                else
                    n=${sigInteger}${sigFraction}" 0"
                    numericType=${__shellfloat_numericTypes[INTEGER]}
                fi
                _shellfloat_setReturnValues ${n} $isNegative $numericType $isScientific
                return $returnCode

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
                _shellfloat_setReturnValues ${n} $isNegative $numericType $isScientific
                return $returnCode

            else
                # exponent == 0 means the number is already aligned as desired
                n=${sigInteger}" "${sigFraction}
                numericType=${__shellfloat_numericTypes[DECIMAL]}
                _shellfloat_setReturnValues ${n} $isNegative $numericType $isScientific
                return $returnCode
            fi

        # Reject strings like xxx[Ee]yyy where xxx, yyy are not valid numbers
        else
            ((returnCode = __shellfloat_ILLEGAL_NUMBER))
            _shellfloat_setReturnValues ""
            return $returnCode
        fi

    # Reject everything else
    else
        ((returnCode = __shellfloat_ILLEGAL_NUMBER))
        _shellfloat_setReturnValues ""
        return $returnCode
    fi
}


function _shellfloat_numToScientific()
{
    local integerPart="$1" fractionalPart="$2"
    local exponent head tail scientific

    if ((integerPart > 0)); then
        ((exponent = ${#integerPart}-1))
        head=${integerPart:0:1}
        tail=${integerPart:1}${fractionalPart}
    elif ((integerPart < 0)); then
        ((exponent = ${#integerPart}-2))   # skip "-" and first digit
        head=${integerPart:0:2}
        tail=${integerPart:2}${fractionalPart}
    else
        [[ "$fractionalPart" =~ ^[-]?(0*)([^0])(.*)$ ]]
        exponent=$((-(${#BASH_REMATCH[1]} + 1)))
        head=${BASH_REMATCH[2]}
        tail=${BASH_REMATCH[3]}
    fi

    # Remove trailing zeros
    [[ $tail =~ ^.*[^0] ]]; tail=${BASH_REMATCH[0]:-0}

    printf -v scientific "%s.%se%s" $head $tail $exponent

    _shellfloat_setReturnValue $scientific
}


################################################################################
# _shellfloat_add (addend_1, addend_2)
################################################################################
function _shellfloat_add()
{
    local n1="$1"
    local n2="$2"

    if ((! __shellfloat_didPrecalc)); then
        _shellfloat_precalc; __shellfloat_didPrecalc=$__shellfloat_true
    fi

    local isVerbose=$(( __shellfloat_isOptimized == __shellfloat_false ))

    # Is the caller itself an arithmetic function?
    local isSubcall=${__shellfloat_false}
    if [[ "${FUNCNAME[1]}" =~ shellfloat_(add|subtract|multiply|divide)$ ]]; then
        isSubcall=${__shellfloat_true}
    fi

    # Handle corner cases where argument count is not 2
    local argCount=$#
    if [[ $argCount -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  addend_1  addend_2"
        return $__shellfloat_SUCCESS
    elif [[ $argCount -eq 1 ]]; then
        # Note the result as-is, print if running "normally", and return
        _shellfloat_setReturnValue $n1
        if (( isVerbose && ! isSubcall )); then echo $n1; fi
        return $__shellfloat_SUCCESS
    elif [[ $argCount -gt 2 ]]; then
        local recursiveReturn

        # Use a binary recursion tree to add everything up
        # 1) left branch
        _shellfloat_add ${@:1:$((argCount/2))}; recursiveReturn=$?
        _shellfloat_getReturnValue n1
        if (( recursiveReturn != __shellfloat_SUCCESS )); then
            _shellfloat_setReturnValue $n1
            return $recursiveReturn
        fi
        # 2) right branch
        _shellfloat_add ${@:$((argCount/2+1))}; recursiveReturn=$?
        _shellfloat_getReturnValue n2
        if (( recursiveReturn != __shellfloat_SUCCESS )); then
            _shellfloat_setReturnValue $n2
            return $recursiveReturn
        fi
        # 3) head node
        _shellfloat_add $n1 $n2; recursiveReturn=$?
        _shellfloat_getReturnValue n2
        _shellfloat_setReturnValue $n2
        return $recursiveReturn
    fi

    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isScientific1 isNegative2 type2 isScientific2
    local flags

    # Check and parse the arguments
    _shellfloat_validateAndParse "$n1";  flags=$?
    _shellfloat_getReturnValues  integerPart1  fractionalPart1  isNegative1  type1  isScientific1
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n1"
        return $?
    fi
    _shellfloat_validateAndParse "$n2";  flags=$?
    _shellfloat_getReturnValues  integerPart2  fractionalPart2  isNegative2  type2  isScientific2
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n2"
        return $?
    fi

    # Quick add & return for integer adds
    if ((type1==type2 && type1==__shellfloat_numericTypes[INTEGER])); then
        if ((isNegative1)); then ((integerPart1*=-1)); fi
        if ((isNegative2)); then ((integerPart2*=-1)); fi
        local sum=$((integerPart1 + integerPart2))
        if (( (!isSubcall) && (isScientific1 || isScientific2) )); then
            _shellfloat_numToScientific $sum "" 
            _shellfloat_getReturnValue sum
        fi
        _shellfloat_setReturnValue $sum
        if (( isVerbose && ! isSubcall )); then
            echo $sum
        fi
        return $__shellfloat_SUCCESS
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
    if (( (!isSubcall) && (isScientific1 || isScientific2) )); then
        _shellfloat_numToScientific "$integerSum" "$fractionalSum"
        _shellfloat_getReturnValue sum
    elif ((fractionalSum)); then
        printf -v sum "%s.%s" $integerSum $fractionalSum
    else
        sum=$integerSum
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $sum
    if (( isVerbose && ! isSubcall )); then
        echo $sum
    fi

    return $__shellfloat_SUCCESS
}


################################################################################
# subtract (subtrahend, minuend)
################################################################################
function _shellfloat_subtract()
{
    local n1="$1"
    local n2="$2"
    local isVerbose=$(( __shellfloat_isOptimized == __shellfloat_false ))

    if ((! __shellfloat_didPrecalc)); then
        _shellfloat_precalc; __shellfloat_didPrecalc=$__shellfloat_true
    fi

    if [[ $# -eq 0 || $# -gt 2 ]]; then
        echo "Usage: ${FUNCNAME[0]}  subtrahend  minuend"
        return $__shellfloat_SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue "$n1"
        if ((isVerbose)); then echo $n1; fi
        return $__shellfloat_SUCCESS
    fi

    # Symbolically negate the second argument
    if [[ "$n2" =~ ^- ]]; then
        n2=${n2:1}
    else
        n2="-"$n2
    fi

    # Calculate, note the result, print if running "normally", and return
    local difference
    _shellfloat_add "$n1" "$n2"
    _shellfloat_getReturnValue difference
    if ((isVerbose)); then
        echo $difference
    fi

    return $?
}


################################################################################
# multiply (multiplicand, multiplier)
################################################################################
function _shellfloat_multiply()
{
    local n1="$1"
    local n2="$2"

    if ((! __shellfloat_didPrecalc)); then
        _shellfloat_precalc; __shellfloat_didPrecalc=$__shellfloat_true
    fi

    local isVerbose=$(( __shellfloat_isOptimized == __shellfloat_false ))

    # Is the caller itself an arithmetic function?
    local isSubcall=${__shellfloat_false}
    if [[ "${FUNCNAME[1]}" =~ shellfloat_(add|subtract|multiply|divide)$ ]]; then
        isSubcall=${__shellfloat_true}
    fi

    # Handle corner cases where argument count is not 2
    local argCount=$#
    if [[ $argCount -eq 0 ]]; then
        echo "Usage: ${FUNCNAME[0]}  factor_1  factor_2"
        return $__shellfloat_SUCCESS
    elif [[ $argCount -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue $n1
        if (( isVerbose && ! isSubcall )); then echo $n1; fi
        return $__shellfloat_SUCCESS
    elif [[ $argCount -gt 2 ]]; then
        local recursiveReturn

        # Use a binary recursion tree to multiply everything out
        # 1) left branch
        _shellfloat_multiply ${@:1:$((argCount/2))}; recursiveReturn=$?
        _shellfloat_getReturnValue n1
        if (( recursiveReturn != __shellfloat_SUCCESS )); then
            _shellfloat_setReturnValue $n1
            return $recursiveReturn
        fi
        # 2) right branch
        _shellfloat_multiply ${@:$((argCount/2+1))}; recursiveReturn=$?
        _shellfloat_getReturnValue n2
        if (( recursiveReturn != __shellfloat_SUCCESS )); then
            _shellfloat_setReturnValue $n2
            return $recursiveReturn
        fi
        # 3) head node
        _shellfloat_multiply $n1 $n2; recursiveReturn=$?
        _shellfloat_getReturnValue n2
        _shellfloat_setReturnValue $n2
        return $recursiveReturn
    fi

    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isScientific1 isNegative2 type2 isScientific2
    local flags

    # Check and parse the arguments
    _shellfloat_validateAndParse "$n1";  flags=$?
    _shellfloat_getReturnValues  integerPart1  fractionalPart1  isNegative1  type1  isScientific1
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n1"
        return $?
    fi
    _shellfloat_validateAndParse "$n2";  flags=$?
    _shellfloat_getReturnValues  integerPart2  fractionalPart2  isNegative2  type2  isScientific2
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n2"
        return $?
    fi

    # Quick multiply & return for integer multiplies
    if ((type1==type2 && type1==__shellfloat_numericTypes[INTEGER])); then
        if ((isNegative1)); then ((integerPart1*=-1)); fi
        if ((isNegative2)); then ((integerPart2*=-1)); fi
        local product=$((integerPart1 * integerPart2))
        if (( (!isSubcall) && (isScientific1 || isScientific2) )); then
            _shellfloat_numToScientific $product "" 
            _shellfloat_getReturnValue product
        fi
        _shellfloat_setReturnValue $product
        if (( isVerbose && ! isSubcall )); then
            echo $product
        fi
        return $__shellfloat_SUCCESS
    fi

    # The product has four components per the distributive law
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

    # Rescale the inner products back to decimals so we can shellfloat_add() them
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

    # Convert to scientific notation if appropriate
    if (( (!isSubcall) && (isScientific1 || isScientific2) )); then
        _shellfloat_numToScientific "${product%.*}" "${product#*.}"
        _shellfloat_getReturnValue product
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $product
    if (( isVerbose && ! isSubcall )); then
        echo $product
    fi

    return $__shellfloat_SUCCESS
}


################################################################################
# divide (dividend, divisor)
################################################################################
function _shellfloat_divide()
{
    local n1="$1"
    local n2="$2"
    local integerPart1  fractionalPart1  integerPart2  fractionalPart2
    local isNegative1 type1 isScientific1 isNegative2 type2 isScientific2

    if ((! __shellfloat_didPrecalc)); then
        _shellfloat_precalc; __shellfloat_didPrecalc=$__shellfloat_true
    fi

    local isVerbose=$(( __shellfloat_isOptimized == __shellfloat_false ))

    local isTesting=${__shellfloat_false}
    if [[ "${FUNCNAME[1]}" == "_shellfloat_assert_functionReturn" ]]; then
        isTesting=${__shellfloat_true}
    fi

    if [[ $# -eq 0 || $# -gt 2 ]]; then
        echo "Usage: ${FUNCNAME[0]}  dividend  divisor"
        return $__shellfloat_SUCCESS
    elif [[ $# -eq 1 ]]; then
        # Note the value as-is and return
        _shellfloat_setReturnValue $n1
        if ((isVerbose)); then echo $n1; fi
        return $__shellfloat_SUCCESS
    fi

    # Throw error on divide by zero
    if ((n2 == 0)); then
        _shellfloat_warn  ${__shellfloat_returnCodes[DIVIDE_BY_ZERO]}  "$arg"
        return $?
    fi

    # Check and parse the arguments
    local flags
    _shellfloat_validateAndParse "$n1";  flags=$?
    _shellfloat_getReturnValues  integerPart1  fractionalPart1  isNegative1  type1  isScientific1
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n1"
        return $?
    fi
    _shellfloat_validateAndParse "$n2";  flags=$?
    _shellfloat_getReturnValues  integerPart2  fractionalPart2  isNegative2  type2  isScientific2
    if ((flags == __shellfloat_ILLEGAL_NUMBER)); then
        _shellfloat_warn  "${__shellfloat_returnCodes[ILLEGAL_NUMBER]}"  "$n2"
        return $?
    fi

    # Convert the division problem to an *integer* division problem by rescaling
    # both inputs so as to lose their decimal points. To obtain maximal precision,
    # we scale up the numerator further, padding with as many zeros as it can hold
    local numerator denominator quotient
    local rescaleFactor zeroCount zeroTail
    ((zeroCount = __shellfloat_precision - ${#integerPart1} - ${#fractionalPart1}))
    ((rescaleFactor = __shellfloat_precision - ${#integerPart1} - ${#fractionalPart2}))
    printf -v zeroTail "%0*s" $zeroCount 0

    # Rescale and rewrite the fraction to be computed, and compute it
    numerator=${integerPart1}${fractionalPart1}${zeroTail}
    denominator=${integerPart2}${fractionalPart2}
    ((quotient = 10#$numerator / 10#$denominator))

    # Rescale back
    if ((rescaleFactor >= ${#quotient})); then
        printf -v quotient "0.%0*s" $rescaleFactor $quotient
    else
        quotient=${quotient:0:(-$rescaleFactor)}"."${quotient:(-$rescaleFactor)}
    fi

    # Determine the sign of the quotient
    if ((isNegative1 != isNegative2)); then
        quotient="-"$quotient
    fi

    if ((isTesting)); then
        # Trim zeros. (Requires decimal point and zero tail.)
        if [[ "$quotient" =~ [\.].*0$ ]]; then
            # If the decimal point IMMEDIATELY precedes the 0s, remove that too
            [[ $quotient =~ [\.]?0+$ ]]
            quotient=${quotient%${BASH_REMATCH[0]}}
        fi
    fi

    # Convert to scientific notation if appropriate
    if ((isScientific1 || isScientific2)); then
        _shellfloat_numToScientific "${quotient%.*}" "${quotient#*.}"
        _shellfloat_getReturnValue quotient
    fi

    # Note the result, print if running "normally", and return
    _shellfloat_setReturnValue $quotient
    if ((isVerbose)); then
        echo $quotient
    fi

    return $__shellfloat_SUCCESS
}

