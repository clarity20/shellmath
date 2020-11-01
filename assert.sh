###############################################################################
# Internal test engine functions
###############################################################################

function _shellfloat_assert_returnCode()
{
    _shellfloat_assert_functionReturn -c "$@"
    return $?
}

function _shellfloat_assert_returnString()
{
    _shellfloat_assert_functionReturn "$@"
#    _shellfloat_getReturnValue returnString
#    echo -n "$returnString"
    return $?
}

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

    # Exercise the function in optimized mode: run faster by avoiding
    # subshelling. Optimized mode also suppresses dumping of function output to stdout.
    __shellfloat_isOptimized=${__shellfloat_true}
    "$func" "${args[@]}"
    returnCode=$?
    __shellfloat_isOptimized=${__shellfloat_false}

    # Fetch the return value(s)
    local numReturnValues
    declare -a actualReturn
    _shellfloat_getReturnValueCount numReturnValues
    if ((numReturnValues == 1)); then
        _shellfloat_getReturnValue actualReturn[0]
    else
        local _i evalString="_shellfloat_getReturnValues"
        for ((_i=0; _i<numReturnValues; _i++)); do
            evalString+=" actualReturn["$_i"]"
        done
        eval $evalString     # no quotes: drop trailing spaces
    fi

    if [[ $mode == RETURN_STRING ]]; then
        if [[ "${actualReturn[*]}" == "$expectedReturn" ]]; then
            _shellfloat_setReturnValue  "ok   "
            return $__shellfloat_SUCCESS
        else
            _shellfloat_setReturnValue "FAIL (${actualReturn[*]}) "
            return $__shellfloat_FAIL
        fi
    elif [[ $mode == RETURN_CODE ]]; then
        if [[ "$returnCode" == "$expectedReturn" ]]; then
            _shellfloat_setReturnValue  "ok   "
            return $__shellfloat_SUCCESS
        else
            _shellfloat_setReturnValue "FAIL ($returnCode) "
            return $__shellfloat_FAIL
        fi
    fi

}

