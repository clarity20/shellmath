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

function _shellfloat_validateAndParse()
{
    local n="$1"
    local isNegative=${__shellfloat_false}
    local numericType

    # Initialize return code to SUCCESS
    __shellFloat_getReturnCode SUCCESS
    local returnCode=$?

    # Strip off leading negative sign, if present
    if [[ "$n" =~ ^[-] ]]; then
        n=${n:1}
        isNegative=${__shellfloat_true}
    fi
    
    # Accept integers
    if [[ "$n" =~ ^[0-9]+$ ]]; then
        numericType=${__shellfloat_numericTypes[INTEGER]}
        echo $n
        return $((numericType|isNegative))

    # Accept decimals: leading digits (optional), decimal point, trailing digits
    elif [[ "$n" =~ ^([0-9]*)\.([0-9]+)$ ]]; then
        numericType=${__shellfloat_numericTypes[DECIMAL]}
        echo ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}
        return $((numericType|isNegative))

    # Accept scientific notation: 1e5, 2.44E+10, etc.
    elif [[ "$n" =~ (.*)[Ee](.*) ]]; then
        local significand=${BASH_REMATCH[1]}
        local exponent=${BASH_REMATCH[2]}

        # Significand must be int or decimal:  1 <= signif < 10
        if [[ "$significand" =~ ^([1-9]\.)?[0-9]+$ ]]; then

            # Exponent must be int with optional sign prefix
            if [[ "$exponent" =~ ^[-+]?[0-9]+$ ]]; then
                numericType=${__shellfloat_numericTypes[SCIENTIFIC]}
                echo $significand $exponent
                return $((numericType|isNegative))
            fi
        fi

    # Reject everything else
    else
        returnCode=${_shellfloat_returnCodes[ILLEGAL_NUMBER]}
        echo ""
        return $returnCode
    fi
}

function _shellfloat_add()
{
    local n1="$1"
    local n2="$2"
    declare -a numericParts
    declare -i flags

    declare -ri SUCCESS=$(_shellfloat_getReturnCode "SUCCESS")
    declare -ri ILLEGAL_NUMBER=$(_shellfloat_getReturnCode "ILLEGAL_NUMBER")

    if [[ $# -eq 0 ]]; then
        echo ""
        return $SUCCESS
    fi

    numericParts=($(_shellfloat_validateAndParse "$n1"))
    flags=$?
    if [[ "$flags" == "$ILLEGAL_NUMBER" ]]; then
    {
        _shellfloat_warn  ${__shellfloat_returnCodes[ILLEGAL_NUMBER]}  "$n1"
        return $?
    }

    if [[ $# -eq 1 ]]; then
        echo $n1
        return $SUCCESS
    elif [[ $# -gt 2 ]]; then
        shift
        n2=$(_shellfloat_add "$@")
        local recursiveReturn=$?
        if [[ "$recursiveReturn" != "$SUCCESS" ]]; then
            echo $n2
            return $recursiveReturn
        fi
    fi

    local integerPart1=${numericParts[0]}
    local fractionalPart1=${numericParts[1]}
    declare isNegative1=$((flags & __shellfloat_true))
    declare type1=$((flags & __shellfloat_allTypes))

    numericParts=($(_shellfloat_validateAndParse "$n2"))
    flags=$?
    if [[ $flags == $ILLEGAL_NUMBER ]]; then
    {
        _shellfloat_warn  ${__shellfloat_returnCodes[ILLEGAL_NUMBER]}  "$n2"
        return $?
    }

    local integerPart2=${numericParts2[0]}
    local fractionalPart2=${mnumericParts2[1]}
    declare isNegative2=$((flags & __shellfloat_true))
    declare type2=$((flags & __shellfloat_allTypes))

    if [[ $type1 == ${__shellfloat_numericTypes[SCIENTIFIC]} \
       || $type2 == ${__shellfloat_numericTypes[SCIENTIFIC]} ]]; then
        echo Scientific notation not yet implemented.
        return 0
    fi


#    sum= ******** do the math ********
#    add negative sign if needed
    echo sum
    return  $(__shellfloat_getReturnCode  "SUCCESS")
}

function _shellfloat_subtract()
{
    return 0
}

function _shellfloat_multiply()
{
    return 0
}

function _shellfloat_divide()
{
    return 0
}

