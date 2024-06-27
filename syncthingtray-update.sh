#!/usr/bin/env bash

project='Martchus'
product='syncthingtray'
product_suffix='x86_64-pc-linux-gnu'
release_link="https://api.github.com/repos/$project/$product/releases"
install_dir="$HOME/.local/bin"
isDebug=false
pkg_version='latest'
execute_features=()
# set by download_package()
download_path=''
# Set by update_or_install()
updating=0

declare -A available_versions

# Array containing mapping of dependency binaries to the packages that contain them.
# This is used in perform_safety_checks() to install missing packages.
# To add a dependency, just add to this mapping.
declare -A deps_bin_to_pkg
deps_bin_to_pkg=(
    ['wget']='wget'
    ['tar']='tar'
    ['curl']='curl'
)

function print_debug_line()
{
    if [ "$isDebug" = true ]; then
        printf "DEBUG: %s\n" "$1"
    fi
}

function usage()
{
    echo "Script to update and install $product.";
    echo "The script should _NOT_ be run as root. It will ask for";
    echo "password via sudo if something needs it.";
    echo "";
    echo "Usage: ${0} [-v version_to_install]";
    echo -e "\n-v\tVersion of $product to install. This version should be";
    echo -e "  \tavailable upstream. Default: latest ($pkg_version)";
    echo -e "\n-i\tInstall path. Default is $install_dir.";
    echo -e "\n-l\tList available versions.";
    echo -e "\n-h\tShow this help message and exit.";
    echo -e "\n-d\tPrint debugging statements.";
    echo -e "\nExample: ${0} -v $pkg_version";
}

function parse_command()
{
    SHORT=v:i:lhd
    LONG=version:,install-dir:,list,help,debug
    PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
    if [[ $? -ne 0 ]]; then
        # e.g. $? == 1
        #  then getopt has complained about wrong arguments to stdout
        exit 1
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
            -i|--install-dir)
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
                exit 2
                ;;
        esac
    done
}

function perform_safety_checks()
{
    # Ensure we are not running as root.
    if [ $EUID -eq 0 ]; then
        echo 'Please do not run this script as root.'
        exit 3
    fi

    # Check if packages are installed
    unavailable_packages=''
    for dep in ${!deps_bin_to_pkg[@]}; do
        which $dep &>/dev/null
        if [ "$?" -gt 0 ]; then
            print_debug_line "${FUNCNAME[0]} : '$dep' from '${deps_bin_to_pkg[$dep]}' is not installed."
            unavailable_packages+="${deps_bin_to_pkg[$dep]} "
        fi
        print_debug_line "${FUNCNAME[0]} : $dep is available."
    done

    # Install missing packages. Exit if installation is unsuccessful.
    if [ -n "$unavailable_packages" ]; then
        echo -e "\nFollowing packages need to be installed:\n$unavailable_packages"
        echo    "Please enter the password for sudo (if prompted)"
        sudo apt install -y $unavailable_packages

        # Check if installation was successful.
        if [ "$?" -ne 0 ]; then
            echo -e "\nSome packages could not be installed successfully. Following command was run:"
            echo -e "sudo yum install -y $unavailable_packages"
            echo -e "\nPlease debug and rerun the script."
            exit 5
        fi
    fi

    # Ensure install path exists.
    if [ ! -d "$install_dir" ]; then
        echo -e "\n$install_dir does not exist. Creating it."

        if ! mkdir -p "$install_dir"; then
            echo -e "\nCouldn't create $install_dir. Retrying with sudo."
            if ! sudo mkdir -p "$install_dir"; then
                echo -e "\nCould not create $install_dir. Bailing."
                exit 6
            fi
            active_user=$(id --user --name)
            active_group=$(id --group --name)
            print_debug_line "${FUNCNAME[0]} : Changing ownership of $install_dir to $active_user:$active_group"
            sudo chown $active_user:$active_group $install_dir
        fi

        echo -e "Created $install_dir"
    fi

    # Ensure install path exists in $PATH
    if [[ "$PATH" != *"$install_dir"* ]]; then
        echo -e "\n$install_dir does not exist \$PATH! Please update your shell's rc file (eg .bashrc) to include it."
    fi

}

function validate_inputs()
{
    # Check if correct version has been supplied. Otherwise downloads will fail.
    [ ${#available_versions[@]} -eq 0 ] && get_available_versions

    is_version_valid='false'
    if [ "$pkg_version" == "latest" ]; then
        pkg_version=$(echo ${!available_versions[@]} | tr ' ' '\n' | sort --version-sort | tail -n 1)
        is_version_valid='true'
    else
        for available_version in ${!available_versions[@]}; do
            if [ "$available_version" == "$pkg_version" ]; then
                is_version_valid='true'
                break
            fi
        done
    fi

    if [ "$is_version_valid" == 'false' ]; then
        echo "'$pkg_version' of $product is not available upstream. Versions available for packaging:"
        print_available_versions
        exit 6
    fi

    print_debug_line "Using version: $pkg_version"
}

function get_available_versions()
{
    print_debug_line "${FUNCNAME[0]} : Getting available versions from $release_link"
    links=$(curl --silent $release_link | grep -oP "https.+$product-\d+\.\d+\.\d+-$product_suffix.tar.xz")
    if [ "$?" -ne 0 ]; then
        echo "Could not fetch releases from $release_link."
        echo "Please verify you are connected to the interwebz."
        echo "Exiting..."
        exit 7
    fi
    for link in $links; do
        ver=$(echo "$link" | cut -f 8 -d '/' | tr -d 'v')
        available_versions["$ver"]=$link
    done
}

function print_available_versions()
{
    echo "Released versions available upstream..."
    [ ${#available_versions[@]} -eq 0 ] && get_available_versions
    # Reference: http://www.tldp.org/LDP/abs/html/arrays.html
    echo ${!available_versions[@]} | tr -s ' ' '\n' | sort --version-sort --reverse
}

function download_package()
{
    core_archive_name=$(basename "${available_versions[$pkg_version]}")
    failed_download='false'

    tmp_dir="$(mktemp --directory -t $product.XXXXX)"
    download_path="$tmp_dir/$core_archive_name"

    # Skip download if file already exists
    if [ -f "$download_path" ]; then
        # check for hash, if possible.
        print_debug_line "$download_path already exists. Not downloading again..."
        return
    fi

    print_debug_line "${FUNCNAME[0]} : Downloading ${available_versions[$pkg_version]} to $download_path"
    wget --no-verbose --output-document="$download_path" "${available_versions[$pkg_version]}"

    # Print a message if download leads to file of size 0, or wget exits with
    # non-zero exit code
    if [ "$?" -ne 0 ] || [ ! -s "$download_path" ]; then
        echo
        echo "Failed to download ${available_versions[$pkg_version]}."
        echo "Please verify if the link is accurate and network connectivity"
        echo "is available."
        failed_download='true'
    fi

    if [ "$failed_download" == 'true' ]; then
        echo -e "\nDownload(s) failed :(. Exiting.\n"
        rm -rf "$tmp_dir"
        exit 8
    fi
}

function update_or_install()
{
    if [ ! -x "$install_dir/$product-$pkg_version-$product_suffix" ]; then
        print_debug_line "${FUNCNAME[0]} : $product is NOT installed."
        updating=0
        return
    fi
    print_debug_line "${FUNCNAME[0]} : $product is already installed."
    echo -e "\nChecking if we have the latest version installed... "
    installed_version=$($install_dir/$product --help | grep -oP 'version \d+\.\d+\.\d+' | cut -f 2 -d ' ')
    if [[ "$pkg_version" == "$installed_version" ]]; then
        echo "Yes ($installed_version)!"
        updating=-1
        exit 0
    fi
    updating=1
}

function install_package()
{
    # Assumes install path is in $PATH already.
    print_debug_line "${FUNCNAME[0]} : Installing $product ($pkg_version)."
    core_archive_name=$(basename "${available_versions[$pkg_version]}")
    tar --directory "$install_dir" --extract --file "$download_path"
    if [ "$?" -ne 0 ]; then
        echo -e "\nFailed extraction. Removing $download_path. Exiting. :(\n"
        cleanup
        exit 9
    fi
    
    # unlink before updating
    test "$updating" -eq 1 && unlink "$install_dir/$product"

    ln -sT "$install_dir/$product-$pkg_version-$product_suffix" "$install_dir/$product"

    if [ "$updating" -eq 1 ]; then
        # Remove all versions except the one we linked to
        echo -e "\nRemoving previous version..."
        for f in $(ls -1 ${install_dir}/${product}-* | grep -v "$pkg_version"); do
            print_debug_line "${FUNCNAME[0]} : Removing $f"
            unlink $f
        done
        echo -e "\nRelaunch using: $install_dir/$product --replace"
    fi
    
    echo "Done."
}

function cleanup()
{
    rm -rf $tmp_dir
}

function main()
{
    ##################
    # Pass all args of the script to the function.
    parse_command "$@"
    for func in ${execute_features[@]}; do
        ($func)
    done
    [ ${#execute_features[@]} -gt 0 ] && exit 0
    perform_safety_checks
    validate_inputs
    update_or_install
    download_package
    install_package
    cleanup
}

main "$@"
