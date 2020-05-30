################################################################################
# shellfloat.sh
# Shell functions for floating-point arithmetic using only builtins
#
# Usage:
#
#    source thisPath/shellfloat.sh
#    add() { echo $(_shellfloat_add "$@"); }    # Rename as desired
#    mySum=$(add 202.895 6.00311)
# 
################################################################################

declare -A __shellfloat_returnCodes=(
    [SUCCESS]="0:Success"
    [FAIL]="1:General failure"
    [ILLEGAL_NUMBER]="2:Invalid decimal number argument: '%s'"
)

declare -A __shellfloat_numericTypes=(
    [INTEGER]=64
    [DECIMAL]=32
    [SCIENTIFIC]=16
)

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
        returnDontExit=TRUE
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

    if [[ $returnDontExit == TRUE ]]; then
        return $returnCode
    else
        exit $returnCode
    fi

}

function _shellfloat_validateNumber()
{
    local n="$1"
    local isNegative=FALSE
    
    # Initialize return code to SUCCESS
    __shellFloat_getReturnCode SUCCESS
    local returnCode=$?

    # Strip off leading negative sign, if present
    if [[ "$n" =~ ^[-] ]]; then
        n=${n:1}
        isNegative=TRUE
    fi
    
    # Accept integers
    if [[ "$n" =~ ^[0-9]+$ ]]; then
        returnCode=${__shellfloat_numericTypes[INTEGER]}
        echo $isNegative
        return $returnCode
    fi

    # Accept decimals: leading digits (optional), decimal point, trailing digits
    if [[ "$n" =~ ^[0-9]*\.[0-9]+$ ]]; then
        returnCode=${__shellfloat_numericTypes[DECIMAL]}
        echo $isNegative
        return $returnCode
    fi

    # Accept scientific notation: 1e5, 2.44E+10, etc.
    if [[ "$n" =~ (.*)[Ee](.*) ]]; then
        local significand=${BASH_REMATCH[1]}
        local exponent=${BASH_REMATCH[2]}

        # Significand must be int or decimal:  1 <= signif < 10
        if [[ "$significand" =~ ^([1-9]\.)?[0-9]+$ ]]; then

            # Exponent must be int with optional sign prefix
            if [[ "$exponent" =~ ^[-+]?[0-9]+$ ]]; then
                returnCode=${__shellfloat_numericTypes[SCIENTIFIC]}
                echo $isNegative
                return $returnCode
            fi
        fi
    fi

    # Reject everything else
    returnCode=${_shellfloat_errorCodes[ILLEGAL_NUMBER]}
    return $returnCode
}

function _shellfloat_add()
{
    local n1="$1"
    local n2="$2"

    _shellfloat_validateNumber "$n1" || \
          _shellfloat_warn  ${__shellfloat_returnCodes[ILLEGAL_NUMBER]}  "$n1"
    _shellfloat_validateNumber "$n2" || \
          _shellfloat_warn  ${__shellfloat_returnCodes[ILLEGAL_NUMBER]}  "$n2"


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

