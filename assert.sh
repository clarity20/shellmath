
function _shellfloat_assert_functionReturn()
{
    if [[ $# -lt 2 ]]; then
        echo 'USAGE: "$FUNCNAME" [-c] returnStringOrCode functionName [ functionArgs ... ]'
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
    args="$@"

    returnString="$("$func" "$args")"
    returnCode=$?

#    echo str: $returnString
#    echo code: $returnCode

    if [[ $mode == RETURN_STRING ]]; then
        if [[ "$returnString" == "$expectedReturn" ]]; then
            echo ok
            return 0
        else
            echo FAIL
            return 1
        fi
    elif [[ $mode == RETURN_CODE ]]; then
        if [[ "$returnCode" == "$expectedReturn" ]]; then
            echo ok
            return 0
        else
            echo FAIL
            return 1
        fi
    fi

}

function _shellfloat_assert_returnCode()
{
    _shellfloat_assert_functionReturn -c "$@"
    return $?
}

function _shellfloat_assert_valueCompare()
{
    if [[ $# != 2 ]]; then
        echo USAGE: "$FUNCNAME" value1 value2
        echo Two input arguments required.
    fi

#    if "$1"
}
