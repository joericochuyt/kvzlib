#!/bin/bash
#/**
# * Displays detailed system information
# * Like serial number, operation system, memory, etc.
# * 
# * @author    Kevin van Zonneveld <kevin@vanzonneveld.net>
# * @copyright 2007 Kevin van Zonneveld (http://kevin.vanzonneveld.net)
# * @license   http://www.opensource.org/licenses/bsd-license.php New BSD Licence
# * @version   SVN: Release: $Id$
# * @link      http://kevin.vanzonneveld.net/
# *
# */

# Includes
###############################################################

# log() was auto-included from '/../functions/log.sh' by make.sh
#/**
# * Logs a message
# * 
# * @param string $1 String
# * @param string $2 Log level. EMERG exists app.
# */
function log(){
    # Levels:
    # EMERG
    # ALERT
    # CRIT
    # ERR
    # WARNING
    # NOTICE
    # INFO
    # DEBUG
    
    # Init
    local line="${1}"
    local levl="${2}"

    # Defaults
    [ -n "${levl}" ] || levl="INFO"
    local show=0
    
    # Allowed to show?  
    if [ "${levl}" == "DEBUG" ]; then
        if [ "${OUTPUT_DEBUG}" = 1 ]; then
            show=1
        fi
    else
        show=1
    fi
    
    # Show
    if [ "${show}" = 1 ];then
        echo "${levl}: ${1}"
    fi
    
    # Die?
    if [ "${levl}" = "EMERG" ]; then
        exit 1
    fi
}

# toUpper() was auto-included from '/../functions/toUpper.sh' by make.sh
#/**
# * Converts a string to uppercase
# * 
# * @param string $1 String
# */
function toUpper(){
   echo "$(echo ${1} |tr '[:lower:]' '[:upper:]')"
}

# commandInstall() was auto-included from '/../functions/commandInstall.sh' by make.sh
#/**
# * Tries to install a package
# * Also saved command location in CMD_XXX
# *
# * @param string $1 Command name
# * @param string $2 Package name
# */
function commandInstall() {
    # Init
    local command=${1}
    local package=${2}
    
    # Show
    echo "Trying to install ${package}"
    
    if [ -n "${CMD_APTITUDE}" ] && [ -x "${CMD_APTITUDE}" ]; then
    	# A new bash session is needed, otherwise apt will break the program flow
        aptRes=$(echo "${CMD_APTITUDE} -yq install ${package}" |bash)
    else
        echo "No supported package management tool found"
    fi
}

# commandTest() was auto-included from '/../functions/commandTest.sh' by make.sh
#/**
# * Tests if a command exists, and returns it's location or an error string.
# * Also saved command location in CMD_XXX.
# *
# * @param string $1 Command name
# * @param string $2 Package name
# */
function commandTest(){
    # Init
    local test="/usr/bin/which"; [ -x "${test}" ] && [ -z "${CMD_WHICH}" ] && CMD_WHICH="${test}"
    local command=${1}
    local package=${2}
    local located=$(${CMD_WHICH} ${command})
    
    # Checks
    if [ ! -n "${located}" ]; then
        echo "Command ${command} not found at all, please install before running this program."
    elif [ ! -x "${located}" ]; then
        echo "Command ${command} not executable at ${located}, please install before running this program."
    else
        echo "${located}" 
    fi
}

# commandTestHandle() was auto-included from '/../functions/commandTestHandle.sh' by make.sh
#/**
# * Tests if a command exists, tries to install package,
# * resorts to 'handler' argument on fail. 
# *
# * @param string $1 Command name
# * @param string $2 Package name. Optional. Defaults to Command name
# * @param string $3 Handler. Optional. (Any of the loglevels. Defaults to emerg to exit app)
# * @param string $4 Additional option. Optional.
# */
function commandTestHandle(){
    # Init
    local command="${1}"
    local package="${2}"
    local handler="${3}"
    local optionl="${4}"
    local success="0"
    local varname="CMD_$(toUpper ${command})"
    
    # Checks
    [ -n "${command}" ] || log "testcommand_handle needs a command argument" "EMERG"
    
    # Defaults
    [ -n "${package}" ] || package=${command}
    [ -n "${handler}" ] || handler="EMERG"
    [ -n "${optionl}" ] || optionl=""
    
    # Test command
    local located="$(commandTest ${command} ${package})"
    if [ ! -x "${located}" ]; then
        if [ "${optionl}" != "NOINSTALL" ]; then
            # Try automatic install
            commandInstall ${command} ${package}
             
            # Re-Test command
            located="$(commandTest ${command} ${package})"
            if [ ! -x "${located}" ]; then
                # Still not found
                log "${located}" "${handler}"
            else
                success=1
            fi
        else
            # Not found, but not going to install
            log "${located}" "${handler}"            
        fi
    else
        success=1
    fi
    
    if [ "${success}" = 1 ]; then
        log "Testing for ${command} succeeded" "DEBUG"
        # Okay, Save location in CMD_XXX variable 
        eval ${varname}="${located}"
    fi
}

# getWorkingDir() was auto-included from '/../functions/getWorkingDir.sh' by make.sh
#/**
# * Determines script's working directory
# * 
# * @author    Kevin van Zonneveld <kevin@vanzonneveld.net>
# * @copyright 2008 Kevin van Zonneveld (http://kevin.vanzonneveld.net)
# * @license   http://www.opensource.org/licenses/bsd-license.php New BSD Licence
# * @version   SVN: Release: $Id: getWorkingDir.sh 89 2008-09-05 20:52:48Z kevin $
# * @link      http://kevin.vanzonneveld.net/
# * 
# * @param string PATH Optional path to add
# */
function getWorkingDir {
    echo $(realpath "$(dirname ${0})${1}")
}

# Essential config
###############################################################
OUTPUT_DEBUG=0

# Check for program requirements
###############################################################
commandTestHandle "bash" "bash" "EMERG" "NOINSTALL"
commandTestHandle "aptitude" "aptitude" "DEBUG" "NOINSTALL" # Just try to set CMD_APTITUDE, produces DEBUG msg if not found
commandTestHandle "egrep" "grep" "EMERG"
commandTestHandle "grep" "grep" "EMERG"
commandTestHandle "awk" "gawk" "EMERG"
commandTestHandle "sort" "coreutils" "EMERG"
commandTestHandle "uniq" "coreutils" "EMERG"
commandTestHandle "realpath" "realpath" "EMERG"
commandTestHandle "sed" "sed" "EMERG"

commandTestHandle "head" "coreutils" "EMERG"
commandTestHandle "free" "procps" "WARNING"
commandTestHandle "df" "coreutils" "WARNING"
commandTestHandle "uname" "coreutils" "WARNING"
commandTestHandle "dmidecode" "dmidecode" "WARNING"

# For windows put this in a .VBS file:
#
# strComputer = "."
# Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" &
# strComputer & "\root\cimv2")
#
# Set colSMBIOS = objWMIService.ExecQuery ("Select * from Win32_SystemEnclosure")
#
# For Each objSMBIOS in colSMBIOS
#   Wscript.Echo "Serial Number: " & objSMBIOS.SerialNumber
# Next

# Run
###############################################################

# If available, dmidecode delivers valuable data like Service Tags
[ -x "${CMD_DMIDECODE}" ] && ${CMD_DMIDECODE} \
    |${CMD_SED} 's#^[\t| ]*##g' \
    |${CMD_EGREP} '(^Serial Number: [a-zA-Z0-9]{7}$|^Product Name: [A-Z]|^Socket Designation: |^Heigth: |^Maximum Capacity: [0-9]{1})' \
    |${CMD_EGREP} -v '(Not Specified$|DIMM|BANK|Cache|A0$|A1$|A2$|A3$)' \
    |${CMD_SED} \
     -e 's#^Serial Number:#Service Tag:#g' \
     -e 's#^Socket Designation:#CPU Socket:#g' \
     -e 's#^Maximum Capacity:#Memory Maximum Capacity:#g' \
     -e 's#@# #g' \
    |${CMD_SORT} \
    |${CMD_UNIQ}

# Memory
[ -x "${CMD_FREE}"] && ${CMD_FREE} -b |${CMD_AWK} '/Mem/ {printf "Memory Netto Size: %1.1f GB\n", ($2/(1024*1024*1024))}'

# Disk
[ -x "${CMD_DF}" ] && ${CMD_DF} -lTP |${CMD_GREP} '/dev/' |${CMD_AWK} '/ext2|ext3|xfs/ {sum+=$3} END {printf "Disk Netto Size: %1.1f GB\n", (sum/(1024*1024))}'

# CPUs
[ -f "/proc/cpuinfo" ] && ${CMD_CAT} /proc/cpuinfo \
    |${CMD_EGREP} '(model name|cpu MHz)' \
    |${CMD_HEAD} -n2 \
    |${CMD_SED} 's#[[:space:]]*:#:#g' \
    |${CMD_SED} \
     -e 's#^model name:#CPU Model:#g' \
     -e 's#^cpu MHz:#CPU MHz:#g'
     
# OS & Kernel
echo -n "Operating System: "
if [ -f /etc/lsb-release ];then
    OS="`echo $(${CMD_CAT} /etc/lsb-release |${CMD_AWK} -F'=' '{print $2}' |${CMD_HEAD} -n3)`"
elif [ -f /etc/redhat-release ]; then
    OS="`echo $(${CMD_CAT} /etc/redhat-release)`"
else
    OS="Unknown"
fi
echo "${OS} ("$(${CMD_UNAME} -m)")"