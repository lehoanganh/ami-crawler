#!/usr/bin/env bash
#set -e
#set -x

# @author: me[at]lehoanganh[dot]de

get_package_manager_info() {
    if which dpkg &> /dev/null; then
        echo "--- Package Manager: DPKG" > $HOME/package_manager_info.txt
        echo "--- OS Info: BEGIN" >> $HOME/package_manager_info.txt
        cat /etc/*release >> $HOME/package_manager_info.txt
        echo "--- OS Info: END" >> $HOME/package_manager_info.txt
        echo "--- Installed Packages Info: BEGIN" >> $HOME/package_manager_info.txt
        dpkg -l >> $HOME/package_manager_info.txt
        echo "--- Installed Packages Info: END" >> $HOME/package_manager_info.txt
    elif which rpm &> /dev/null; then
        echo "--- Package Manager: RPM" > $HOME/package_manager_info.txt
        echo "--- OS Info: BEGIN" >> $HOME/package_manager_info.txt
        cat /etc/*release >> $HOME/package_manager_info.txt
        echo "--- OS Info: END" >> $HOME/package_manager_info.txt
        echo "--- Installed Packages Info: BEGIN" >> $HOME/package_manager_info.txt
        rpm -qa >> $HOME/package_manager_info.txt
        echo "--- Installed Packages Info: END" >> $HOME/package_manager_info.txt
    else
        echo "--- Package Manager: UNKNOWN" > $HOME/package_manager_info.txt
        echo "--- OS Info: BEGIN" >> $HOME/package_manager_info.txt
        cat /etc/*release >> $HOME/package_manager_info.txt
        echo "--- OS Info: END" >> $HOME/package_manager_info.txt
    fi
}

get_ohai_info() {
    if which dpkg &> /dev/null; then
        echo "::: DPKG Package Manager..."
        if grep -i "Ubuntu" $HOME/package_manager_info.txt; then
            echo "::: Ubuntu Distro..."

            # too much ifs
            # but it is better then nested conditions
            if grep -i "Ubuntu 12.04" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 11.10" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 11.04" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 10.10" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 10.04" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 9.10" $HOME/package_manager_info.txt; then
                ohai_support
            elif grep -i "Ubuntu 9.04" $HOME/package_manager_info.txt; then
                ohai_support
            else
                ohai_no_support
            fi

        # NOT Ubuntu Distro
        else
            echo "NOT Ubuntu Distro..."
            ohai_no_support
        fi
    else
        echo "::: NOT DPKG Package Manager..."
        ohai_no_support
    fi
}

ohai_no_support() {
    echo "Ohai for now is not supported by the system" > $HOME/ohai_info.json
    echo "Read in package_manager_info.json for more details" >> $HOME/ohai_info.json
}

ohai_support() {
    echo "::: Update..."
    sudo apt-get update -qq
    echo "::: Install Ohai..."
    sudo apt-get install ohai -qq
    echo "::: Run Ohai..."
    ohai > $HOME/ohai_info.json
}

# Introspection
get_package_manager_info

get_ohai_info
