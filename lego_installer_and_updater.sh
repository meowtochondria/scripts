#!/bin/bash

###########################################
# Description                             #
###########################################
# Script to install and update Let's Encrypt's certificate manager go client - lego (https://github.com/go-acme/lego)
# on shared hosting providers like Namecheap.

###########################################
# Some initializations                    #
###########################################
project='go-acme'
product='lego'
pkg_version='latest'
isDebug=false
release_link="https://api.github.com/repos/$project/$product/releases"
install_dir="$HOME/bin"
tmp='/tmp/lego'
execute_features=()
declare -A available_versions

###########################################
# Functions                               #
###########################################
function print_debug_line()
{
    if [ "$isDebug" = true ]; then
        printf "DEBUG: %s \n" "$1"
    fi
}

function usage()
{
    echo "Script to setup and update $product.";
    echo "The script should _NOT_ be run as root. It will ask for";
    echo "password via sudo if something needs it.";
    echo "";
    echo "Usage: ${0} [-v version_to_install]";
    echo -e "\n-v\tVersion of $product to install. This version should be";
    echo -e "  \tavailable upstream. Default: latest ($pkg_version)";
    echo -e "\n-i\tInstallation path. Default is $install_dir.";
    echo -e "\n-l\tList available versions.";
    echo -e "\n-h\tShow this help message and exit.";
    echo -e "\n-d\tPrint debugging statements.";
    echo -e "\nExample: ${0} -v $pkg_version";
}

function parse_command()
{
    SHORT=v:i:lhd
    LONG=version:,install_path:,list,help,debug
    PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
    if [[ "$?" -ne 0 ]]; then
        # e.g. $? == 1
        #  then getopt has complained about wrong arguments to stdout
        exit 4
    fi

    # use eval with "$PARSED" to properly handle the quoting
    eval set -- "$PARSED"

    # Parse options until we see --
    while true; do
        case "$1" in
            -d|--debug)
                isDebug=true;
                print_debug_line "ON";
                shift
                ;;
            -v|--version)
                pkg_version="$2"
                shift 2
                ;;
            -i|--install_path)
                install_dir="$2"
                shift 2
                ;;
            -l|--list)
                execute_features+=('print_available_versions')
                shift
                ;;
            -h|--help)
                execute_features+=('usage')
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo -e "\nProgrammer has the dumbz."
                exit 3
                ;;
        esac
    done
}

function perform_safety_checks()
{
    # Ensure we are not running as root.
    if [ $EUID -eq 0 ]; then
        echo 'Please do not run this script as root.'
        exit 1
    fi
}

function validate_inputs()
{
    # Check if correct version has been supplied. Otherwise downloads will fail.
    [ ${#available_versions[@]} -eq 0 ] && get_available_versions

    is_version_valid='false'
    if [ "$pkg_version" == "latest" ]; then
        pkg_version=$(get_latest_version)
        is_version_valid='true'
    else
        for available_version in "${!available_versions[@]}"; do
            if [ "$available_version" == "$pkg_version" ]; then
                is_version_valid='true'
                break
            fi
        done
    fi

    if [ "$is_version_valid" == 'false' ]; then
        echo "'$pkg_version' of $product is not available upstream. Versions available:"
        print_available_versions
        exit 2
    fi

    print_debug_line "Using version: $pkg_version"
}

function get_available_versions()
{
    print_debug_line "${FUNCNAME[0]} : Getting available versions from $release_link"
    for link in $(curl --silent $release_link | grep -oP "https.+${product}_v\d+\.\d+\.\d+_linux_amd64.tar.gz"); do
        ver=$(echo "$link" | cut -f 8 -d '/' | tr -d 'v')
        available_versions["$ver"]=$link
    done
}

function print_available_versions()
{
    echo "Versions available upstream..."
    [ ${#available_versions[@]} -eq 0 ] && get_available_versions
    # Reference: http://www.tldp.org/LDP/abs/html/arrays.html
    echo "${!available_versions[@]}" | tr -s ' ' '\n' | sort --version-sort --reverse
}

function get_latest_version()
{
    [ ${#available_versions[@]} -eq 0 ] && get_available_versions
    echo "${!available_versions[@]}" | tr ' ' '\n' | sort --version-sort | tail -n 1
}

function is_update_needed()
{
    # This function checks if $product is installed, or if installed version is < latest version upstream.
    # Returns 0 if update is needed, 1 if not.
    if command -v $product &>/dev/null ; then
        print_debug_line "${FUNCNAME[0]} : $product is installed."
    else
        print_debug_line "${FUNCNAME[0]} : $product is NOT installed."
#         return 1
    fi

    latest_available_version=$(get_latest_version)
    installed_version=$($product --version | grep -oP '(\d+\.){2}\d+')

    print_debug_line "${FUNCNAME[0]} : latest_available_version = $latest_available_version, installed_version = $installed_version."
    if [ "$latest_available_version" = "$installed_version" ]; then
        echo "Installed version is same as latest available version upstream: $installed_version"
        return 1
    fi

    return 0
}

function download_and_install_package()
{
    core_archive_name=$(basename "${available_versions[$pkg_version]}")
    failed_download='false'

    # Skip download if file already exists
    if [ -f "$tmp/$core_archive_name" ] && [ ! -s "$tmp/$core_archive_name" ]; then
        print_debug_line "$tmp/$core_archive_name already exists. Not downloading again..."
    else
        print_debug_line "${FUNCNAME[0]} : Downloading ${available_versions[$pkg_version]} to $tmp/$core_archive_name"
        mkdir -p "$tmp"
        wget -O "$tmp/$core_archive_name" "${available_versions[$pkg_version]}"

        # Print a message if download leads to file of size 0
        if [ ! -s "$tmp/$core_archive_name" ]; then
            echo
            echo "Failed to download ${available_versions[$pkg_version]}."
            echo "Please verify if the link is accurate and network connectivity"
            echo "is available."
            failed_download='true'
        fi

        if [ "$failed_download" == 'true' ]; then
            echo -e "\nDownload(s) failed :(. Exiting.\n"
            exit 4
        fi

    fi

    echo -e "\nNow extracting $core_archive_name..."
    tar --directory="$install_dir" --gzip --extract --verbose --file="$tmp/$core_archive_name"
    if [ "$?" -ne 0 ]; then
        echo -e "\nFailed to extract downloaded archive - $install_dir/$core_archive_name"
        echo -e "\nFailed command: tar --directory=\"$install_dir\" --gzip --extract --verbose --file=\"$tmp/$core_archive_name\""
        exit 5
    fi

    # Remove archive once its all done.
    rm -f "$tmp"

    echo -e "\n\nInstallation was successful!\nInvoking lego --version to verify expected version was installed.\n"
    "$install_dir/lego" --version
}


###########################################
# Main/Entry point                        #
###########################################
# Pass all args of the script to the function.
parse_command "$@"
perform_safety_checks
validate_inputs
for func in "${execute_features[@]}"; do
    ($func)
done
# If we were only using one off flags, then exit. Condition is checked by counting number of elements in execute_features array.
[ ${#execute_features[@]} -gt 0 ] && exit 0
# Gracefully exit if update is not needed.
is_update_needed || exit 0
download_and_install_package
