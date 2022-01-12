# Copyright (c) Anton Zelenov.
#
# This file is released under the 0-clause BSD License.
# Refer the 0BSD.txt file for the full text of the license.

# stdErr
e()  { "$@" >&2; }

# Trace
t()  { e echo "+ $*"; "$@"; }

# Force
f()  { if "$@"; then err=0; else err=$?; fi }

# Quiet
q()  { "$@" &>/dev/null; }
# Quiet stdOut
qo() { "$@" 1>/dev/null; }
# Quiet stdErr
qe() { "$@" 2>/dev/null; }
