#!/bin/bash
#
# Netbox upgrade script.
# This is experimental and never run in production yet however it follows all previous successful steps.
# 2021 - Adam Boutcher - IPPP, Durham University (UKI-SCOTGRID-DURHAM).
#

# Function to check that a binary exists
function check_bin() {
  which $1 1>/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "$1 cannot be found. Please install it or add it to the path. Exiting."
    exit 1
  fi
}

check_bin which
check_bin whoami
check_bin echo
check_bin test
check_bin wget
check_bin tar
check_bin cp
check_bin ln
check_bin rm
check_bin systemctl

#Check we're root
if [[ $(whoami) != "root" ]]; then
  >&2 echo "Please Run as root";
  exit 1;
fi

if [ $# != 0 ] && ([ $1 = "-h" ] || [ $1 = "--help" ] || [ $1 = "-u" ] || [ $1 = "--usage" ]); then
  echo "Netbox Upgrade Script."
  echo "-p --previous          Previous Version"
  echo "-l --latest            Latest Version to upgrade to."
  echo "-d --dir               Directory Netbox is installed. Default is /opt."
  echo "-h --help              This screen"
  echo "-u --usage             Same as -h --help"
  echo ""
  echo "Example:"
  echo "  $0 -p 1.2.3 -l 2.3.4 [-d /opt]"
  echo ""
  exit 0
else
  while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
      -p|--previous)
        PRE="$2"
        shift
      ;;
      -l|--latest)
        LAT="$2"
        shift
      ;;
      -d|--dir)
        DIR="$2"
        shift
      ;;
      *)
        >&2 echo "Wrong Arguments Supplied."
        >&2 echo "Check --usage for usaged details."
        exit 1
      ;;
    esac
    shift
  done
fi

if [[ -z $DIR ]]; then
  DIR="/opt"
fi
if [[ -z $PRE ]]; then
  >&2 echo "Missing Arguments Supplied."
  >&2 echo "Check --usage for usaged details."
  exit 1
fi
if [[ -z $LAT ]]; then
  >&2 echo "Missing Arguments Supplied."
  >&2 echo "Check --usage for usaged details."
  exit 1
fi

# Check for Previous directory
if [[ $(test -d ${DIR}/netbox-${PRE}) -eq 1 ]]; then
  >&2 echo "Previous version not found."
  exit 2
fi

echo "1. Downloading latest archive"
wget -q https://github.com/netbox-community/netbox/archive/v${LAT}.tar.gz -O ${DIR}/latest.tar.gz
if [[ $? != 0 ]]; then
  >&2 echo "Cannot find the latest version on GitHub."
  exit 3
fi
tar -xzf ${DIR}/latest.tar.gz -C /opt

echo "2. Copying Configs and reports etc"
# Check for Latest directory
if [[ $(test -d ${DIR}/netbox-${LAT}) -eq 1 ]]; then
  >&2 echo "Latest version not found."
  exit 2
fi
cp -pr ${DIR}/netbox-${PRE}/local_requirements.txt ${DIR}/netbox-${LAT}/
cp -pr ${DIR}/netbox-${PRE}/gunicorn.py ${DIR}/netbox-${LAT}/
cp -pr ${DIR}/netbox-${PRE}/netbox/netbox/configuration.py ${DIR}/netbox-${LAT}/netbox/netbox/
cp -pr ${DIR}/netbox-${PRE}/netbox/netbox/ldap_config.py ${DIR}/netbox-${LAT}/netbox/netbox/
cp -pr ${DIR}/netbox-${PRE}/netbox/{media,scripts,reports} ${DIR}/netbox-${LAT}/netbox/

if [ -f /usr/bin/python3.8 ]; then
  echo "2.5. Setting Python 3 Version"
  alias python3="/usr/bin/python3.8"
fi

echo "3. Running Upgrade Script"
cd ${DIR}/netbox-${LAT}
./upgrade.sh
EXT=$?
if [[ $EXT != 0 ]]; then
  >&2 echo "Netbox upgrade failed, check the output or run manually."
  exit $EXT
fi
cd -

echo "4. Symlinking the version to live"
rm ${DIR}/netbox
ln -sfn ${DIR}/netbox-${LAT}/ ${DIR}/netbox

echo "5. restarting services"
systemctl restart netbox netbox-rq

echo "Done!"
exit 0
