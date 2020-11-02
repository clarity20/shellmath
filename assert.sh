###############################################################################
# Internal test engine functions
###############################################################################

function _shellmath_assert_returnCode()
{
    _shellmath_assert_functionReturn -c "$@"
    return $?
}

function _shellmath_assert_returnString()
{
    _shellmath_assert_functionReturn "$@"
#    _shellmath_getReturnValue returnString
#    echo -n "$returnString"
    return $?
}

function _shellmath_assert_functionReturn()
{
    if [[ $# -lt 2 ]]; then
        echo 'USAGE: "${FUNCNAME[0]}" [-c] returnStringOrCode functionName [ functionArgs ... ]'
        echo "    By default, asserts against the string output by the function."
        echo "    Use -c to assert against the numeric return code instead."
        return ${__shellmath_returnCodes[FAIL]}
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

    # Exercise the function in optimized mode; it will run faster by avoiding
    # subshelling. This also suppresses dumping of function output to stdout.
    __shellmath_isOptimized=${__shellmath_true}
    "$func" "${args[@]}"
    returnCode=$?
    __shellmath_isOptimized=${__shellmath_false}

    # Fetch the return value(s)
    local numReturnValues
    declare -a actualReturn
    _shellmath_getReturnValueCount numReturnValues
    if ((numReturnValues == 1)); then
        _shellmath_getReturnValue actualReturn[0]
    else
        # Multiple returns? Join them into one string
        local _i evalString="_shellmath_getReturnValues"
        for ((_i=0; _i<numReturnValues; _i++)); do
            evalString+=" actualReturn["$_i"]"
        done
        eval $evalString
    fi

    if [[ $mode == RETURN_STRING ]]; then
        if [[ "${actualReturn[*]}" == "$expectedReturn" ]]; then
            _shellmath_setReturnValue  "ok   "
            return $__shellmath_SUCCESS
        else
            _shellmath_setReturnValue "FAIL (${actualReturn[*]}) "
            return $__shellmath_FAIL
        fi
    elif [[ $mode == RETURN_CODE ]]; then
        if [[ "$returnCode" == "$expectedReturn" ]]; then
            _shellmath_setReturnValue  "ok   "
            return $__shellmath_SUCCESS
        else
            _shellmath_setReturnValue "FAIL ($returnCode) "
            return $__shellmath_FAIL
        fi
    fi

}

