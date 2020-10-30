function _shellfloat_assert_returnCode()
{
    _shellfloat_assert_functionReturn -c "$@"
    return $?
}

function _shellfloat_assert_returnString()
{
    echo -n "$(_shellfloat_assert_functionReturn "$@")"
    return $?
}


function _shellfloat_assert_equal()
{
    if [[ $# != 2 ]]; then
        echo USAGE: "${FUNCNAME[0]}" value1 value2
        echo Two input arguments required.
    fi
}

###############################################################################
# Internal functions
###############################################################################

function _shellfloat_assert_functionReturn()
{
    if [[ $# -lt 2 ]]; then
        echo 'USAGE: "${FUNCNAME[0]}" [-c] returnStringOrCode functionName [ functionArgs ... ]'
        echo "    By default, asserts against the string output by the function."
        echo "    Use -c to assert against the numeric return code instead."
        return ${__shellfloat_returnCodes[FAIL]}
    fi

    if [[ "${1,,}" == '-c' ]]; then
        mode=RETURN_CODE
        shift
    else
        mode=RETURN_STRING
    fi

    expectedReturn="$1"
    func="$2"
    shift 2

    args=("$@")

    __shellfloat_isOptimized=${__shellfloat_true}
    "$func" "${args[@]}"
    returnCode=$?
    __shellfloat_isOptimized=${__shellfloat_false}

    # Fetch the return value. In shellfloat, there should always be just one.
    local actualReturn
    _shellfloat_getReturnValue actualReturn

    resultFormat="%-5s"

    if [[ $mode == RETURN_STRING ]]; then
        if [[ "$actualReturn" == "$expectedReturn" ]]; then
            printf $resultFormat ok
            return 0
        else
            printf $resultFormat FAIL
            return 1
        fi
    elif [[ $mode == RETURN_CODE ]]; then
        if [[ "$returnCode" == "$expectedReturn" ]]; then
            printf $resultFormat ok
            return 0
        else
            printf $resultFormat FAIL
            return 1
        fi
    fi

}

