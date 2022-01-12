# Copyright (c) Anton Zelenov.
#
# This file is released under the 0-clause BSD License.
# Refer the 0BSD.txt file for the full text of the license.

set -Eeuo pipefail
shopt -s inherit_errexit
shopt -s failglob

script="$(which "$0" 2>/dev/null || realpath "$0")"
lib_dir="$(dirname "$script")/mz-lib"
. "$lib_dir/shorts.bash"
. "$lib_dir/trap.bash"

usage()
{
    cat <<-'EOF'
		Creates git bundle of remote repository.

		Usage:
		  git-bundle [OPTION]... REPOSITORY-URL

		Options:
		  --7z          Pack bundle to 7zip archive.
		  --dic-size    Dictionary size for 7zip compression (default: 64m).
		  --anon        Name bundle inside 7zip archive as repo.bundle so as to avoid
		                filename inconsistency when renaming 7zip archive.
		  --help        Print this help.
	EOF
}

suggest_help()
{
    e echo "Try 'git-bundle --help' for more information."
    return 1
}

require()
{
    local args_req args_total
    args_req=$2
    args_total=$(($3 - 1)) # Decrease by 1 because args contain option key itself.

    if (($args_total < $args_req)); then
        e echo "Error: option '$1' requires $2 argument(s)."
        suggest_help
    fi
}

# Parse arguments.
{
    o7z=0
    o7z_ds=64m
    o7z_anon=0

    args=()
    while (($#)); do
        case "$1" in
            --7z)
                o7z=1
            ;;
            --dic-size)
                require "$1" 1 $#
                shift
                o7z_ds="$1"
            ;;
            --anon)
                o7z_anon=1
            ;;
            -h|--help)
                usage
                exit 0
            ;;
            --)
                shift
                args+=("$@")
                break
            ;;
            -*)
                e echo "Error: unknown option '$1'."
                suggest_help
            ;;
            *)
                args+=("$1")
            ;;
        esac
        shift
    done

    if (( ${#args[@]} != 1 )); then
        e echo "Error: expected 1 argument, but given ${#args[@]}."
        suggest_help
    fi

    url="${args[0]}"
}

# Define helper variables.
{ 
    repo="$(basename "$url")"
    name="${repo%.*}" # filename without extension.

    # Determine bundle name.
    bundle_name="$name"
    if (($o7z)); then
        if (($o7z_anon)); then
            bundle_name="repo"
        fi

        # Do not overwrite existing files by temporary files.
        if [[ -e "$bundle_name.bundle" || -e "$bundle_name.url" ]]; then
            e echo "Error: cannot create bundle ('$bundle_name.bundle' or '$bundle_name.url' files already exist)."
            exit 1
        fi

        trap_add 'f rm -f "$bundle_name.bundle" "$bundle_name.url"' EXIT
    fi
}

# Do the actual job.
{
    # Clone repository.
    t git clone --mirror "$url" "$repo"
    trap_add 'f rm -rf "$repo"' EXIT

    # Create bundle file.
    (
        t cd "$repo"
        t git gc --aggressive --prune=now
        t git bundle create "../$bundle_name.bundle" --all
    )
    trap_add 'f rm -f "$bundle_name.bundle"' ERR

    # Create url file.
    echo "$url" > "$bundle_name.url"
    trap_add 'f rm -f "$bundle_name.url"' ERR

    # Pack to 7z if needed.
    if (($o7z)); then
        t rm -f "$name.7z"
        # -ms=off, solid is OFF, since we put just 2 unrelated files in archive.
        e t 7z a -t7z "$name.7z" -m0=lzma2 -mx=9 -mfb=64 "-md=$o7z_ds" -ms=off -mmt "$bundle_name.bundle" "$bundle_name.url"
    fi
}
