#!/bin/bash

runner_os=$1
runner_name=$2
root_version=$3

if [[ -z ${GITHUB_ACTION+z} ]]; then
    ECHO=echo
else
    ECHO=
fi

# From https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# $1 - runner os
# $2 - runner name
# $3 - root_version
function install_root {
#     declare -A root_names_defaults
#     declare -A root_versions_defaults
#     root_versions_defaults['ubuntu-latest']=6.30.02

    name_pattern=
    latest_version=6.30.02

    case $2 in
        ubuntu-latest | ubuntu-22.04)
            case $3 in
                latest | 6.30*)
                    name_pattern="root_v%s.Linux-ubuntu22.04-x86_64-gcc11.4.tar.gz"
                    ;;
                *)
                    name_pattern="root_v%s.Linux-ubuntu22-x86_64-gcc11.4.tar.gz"
                    ;;
            esac
            ;;
        ubuntu-20.04)
            case $3 in
                latest | 6.30*)
                    name_pattern="root_v%s.Linux-ubuntu20.04-x86_64-gcc9.4.tar.gz"
                    ;;
                *)
                    name_pattern="root_v%s.Linux-ubuntu20-x86_64-gcc9.4.tar.gz"
                    ;;
            esac
            ;;
        windows-latest | windows-2022)
            name_pattern="root_v%s.win64.vc17.zip"
            ;;
        windows-2019)
            name_pattern="root_v%s.win64.vc17.zip"
            ;;
        macos-latest | macos-12)
            name_pattern="root_v%s.macos-12.7-x86_64-clang140.tar.gz"
            ;;
        macos-11)
            echo "::error ::Runner not supported '$1'"
            exit 1
            ;;
        *)
            echo "::error ::Runner not known '$1'"
            exit 1
            ;;
    esac

    case $3 in
        latest | "")
            selected_version=$latest_version
            ;;
        *)
            selected_version=$3
            ;;
    esac

    vercomp $selected_version $latest_version
    res=$?

    case $res in
        1)
            echo "::error ::Version not supported '$selected_version'"
            exit 1
            ;;
        *)
            ;;
    esac

    root_file=$(printf $name_pattern $selected_version)
    download_path="https://root.cern/download/$root_file"

    case $1 in
        Linux)
            echo "::group::install tools"
            $ECHO sudo apt-get install wget tar -y
            echo "::endgroup::"
            echo "::group::download from $download_path"
            $ECHO wget --quiet $download_path
            $ECHO sudo tar -xzf $root_file -C /usr/local
            echo "::endgroup::"
            echo "rootsys=/usr/local/root" >> $GITHUB_OUTPUT
            ;;
        Windows)
            echo "::error ::Windows not yet supported"
            exit 1
            ;;
        macOS)
            echo "::error ::macOS not yet supported"
            ;;
        *)
            echo "::error ::Unsupported runner '$1'"
            exit 1
            ;;
    esac
}

echo Running with $1,$2,$3
install_root $runner_os $runner_name $root_version
