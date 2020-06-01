#!/usr/bin/env bash

###############################################################################
# runTests.sh
#
# Usage: runTests.sh  [testFile]
#        where testFile defaults to testCases.in
#
# Processes a test file such as the testCases.in included with this package
###############################################################################

# Process one line from the test cases file. Invoked below through mapfile.
function _shellfloat_runTests()
{
    local lineNumber=$1
    local text=$2

    # Enable line continuation. Cannot access global storage
    # inside a mapfile function call, so we use the disk.
    local COMMAND_BUFFER=/tmp/shellfloat.tmp

    # Trim leading whitespace
    [[ $text =~ ^[$' \t']*(.*) ]]
    text=${BASH_REMATCH[1]}

    # Skip comments and blank lines
    [[ "$text" =~ ^# || -z $text ]] && return 0

    # Check for line continuation
    local len="${#text}"
    if [[ ${text:$((len-1))} == '\' ]]; then

        # Eat the continuation character and add to the buffer
        echo -n "${text/%\\/ }" >> "$COMMAND_BUFFER"
        
        # Defer processing
        return

    # No line continuation
    else

        # Assemble the command
        local command
        if [[ -s "$COMMAND_BUFFER" ]]; then
            command="$(<$COMMAND_BUFFER)$text"
        else
            command=$text
        fi

        # Process the command
        echo The command is "$command"

        # Empty the command buffer
        : > "$COMMAND_BUFFER"
    fi

}

mapfile -t -c 1 -C _shellfloat_runTests < "${1:-testCases.in}"

rm -f /tmp/shellfloat.tmp

