####################################################################################
# shellfloat.sh
# Shell functions for floating-point arithmetic using only built-in shell features
#
# Usage:
#
# source shellfloat.sh
# sum="$(add 77.8002 -5)"
# difference="$(sub 145.22 33.9)"
# p1=9.0909;  p2=88.8
# product="$(mul $p1 $p2)"
# quotient="$(div a_1 a_2)"
###################################################################################

declare -A __shellfloat_returnCodes=(
    [SUCCESS]="0:Success"
    [FAIL]="1:General failure"
    [NON_DECIMAL]="2:Not a decimal number: %s"
)

function _shellfloat_getReturnCode()
{
    errorName="$1"
    return ${__shellfloat_returnCodes[$errorName]%%:*}
}

function _shellfloat_errorOut()
{
    # Argument 1 format:  returnCode:msgTemplate
    [[ "$1" =~ ^([0-9]+):(.*) ]]
    returnCode=${BASH_REMATCH[1]}
    msgTemplate=${BASH_REMATCH[2]}

    shift
    msgTemplateValues="$@"
    
    printf  "$msgTemplate"  "${msgTemplateValues[@]}"
    return $returnCode
}

function _shellfloat_validateDecimal()
{
    n="$1"
    isNegative=FALSE
    
    # Accept a leading negative sign
    if [[ "$n" =~ ^[-] ]]; then
        n=${n:1}
        isNegative=TRUE
    fi
    
    [[ "$n" =~ ^[0-9]+$ ]] && return ${__shellfloat_returnCodes[SUCCESS]%%:*}
}

function add()
{
    a_1="$1"
    a_2="$2"

    _shellfloat_validateDecimal "$a_1" || return  $(_shellfloat_errorOut  $(_shellfloat_getReturnCode "NON_DECIMAL")  "$a_1")
    _shellfloat_validateDecimal "$a_2" || return  $(_shellfloat_errorOut  $(_shellfloat_getReturnCode "NON_DECIMAL")  "$a_2")


#    sum= ******** do the math ********

    echo sum
    return  $(__shellfloat_getReturnCode  "SUCCESS")
}

