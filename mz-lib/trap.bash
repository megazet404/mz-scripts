# Copyright (c) Anton Zelenov.
#
# This file is released under the 0-clause BSD License.
# Refer the 0BSD.txt file for the full text of the license.

# Check if argument is number.
is_num()
{
    [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
}

# Convert signal name to signal number.
to_sig_num()
{
    if is_num "$1"; then
      # Signal is already number.
      kill -l "$1" >/dev/null # Check that signal number is valid.
      echo    "$1"            # Return result.
    else
      # Convert to signal number.
      kill -l "$1"
    fi
}

trap_add()
{
    local cmd sig sig_num

    cmd="$1"
    sig="$2"
    sig_num=$(to_sig_num "$sig")

    # Avoid inheriting trap commands from outer shell.
    if [[ "${trap_subshell[$sig_num]:-}" != "$BASH_SUBSHELL" ]]; then
        # We are in new subshell, don't take commands from outer shell.
        trap_subshell[$sig_num]="$BASH_SUBSHELL"
        trap_cmds[$sig_num]=
    fi

    # Combine new and old commands. Separate them by newline.
    trap_cmds[$sig_num]="$cmd
${trap_cmds[$sig_num]}"

    trap -- "${trap_cmds[$sig_num]}" $sig
}

trap_subshell=
trap_cmds=
