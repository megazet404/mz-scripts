# Copyright (c) Anton Zelenov.
#
# This file is released under the 0-clause BSD License.
# Refer the 0BSD.txt file for the full text of the license.

set -euo pipefail
shopt -s inherit_errexit
shopt -s failglob

script="$(which "$0" 2>/dev/null || realpath "$0")"
lib_dir="$(dirname "$script")/mz-lib"
. "$lib_dir/trap.bash"
. "$lib_dir/shorts.bash"

usage()
{
    cat <<-'EOF'
		Restores repository from git bundle.

		Usage:
		  git-unbundle BUNDLE [OPTION]...

		Options are any 'git clone' options (e.g. '--bare').

		Note that unbundling to custom directory is not supported.
	EOF
}

# Parse args.
{
    if (($# == 0)); then
        e echo "Error: argument is expected."
        e echo "Try 'git-unbundle --help' for more information."
        exit 1
    fi

    if [[ "$1" = "--help" || "$1" == "-h" ]]; then
        usage
        exit 0
    fi

    bundle="$1"
    shift
}

# Define helper variables.
{
    path_name="${bundle%.*}"        # Path without extension.
    name="$(basename "$path_name")" # Filename without extension.
    ext="${bundle##*.}"             # Extension.
}

# Do the job.
{
    # Get bundle from 7z archive.
    if [[ "$ext" == "7z" ]]; then
        # Unpack archive.
        e t 7z x "$bundle" "-o$name.unpacked" >/dev/null
        trap_add 'f rm -rf "$name.unpacked"' EXIT

        # Find bundles among extracted files.
        bundles=("$name.unpacked"/*.bundle)

        # Check number of bundles.
        if ((${#bundles[@]} == 0)); then
            e echo "Error: no bundle in \"$bundle\"."
            exit 0
        elif ((${#bundles[@]} > 1)); then
            e echo "Error: too many bundles in \"$bundle\"."
            exit 0
        fi

        # Rename bundle to archive name.
        if [[ "${bundles[0]}" != "$name.unpacked/$name.bundle" ]]; then
            t mv -f "${bundles[0]}"        "$name.unpacked/$name.bundle"
            t mv -f "${bundles[0]%.*}.url" "$name.unpacked/$name.url"
        fi

        # Update variables to point to extracted bundle.
        bundle="$name.unpacked/$name.bundle"
        path_name="${bundle%.*}"
    fi

    # Determine repository name.
    repo="$name"
    for opt in "$@"; do
        if [[ "$opt" == "--bare" || "$opt" == "--mirror" ]]; then
            repo+=".git"
            break
        fi
    done

    # Clone repository.
    t git clone "$@" -- "$bundle" "$repo"
    trap_add 'f rm -rf "$repo"' ERR

    # Set remote url.
    (
        url="$(cat "$path_name.url")"
        t cd "$repo"
        t git remote set-url origin "$url"
    )
}
