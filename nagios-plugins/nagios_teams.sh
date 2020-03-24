#!/bin/bash
# Nagios Notifications for MS-Teams Webhooks

# ./nagios_teams.sh --url https://outlook.office.com/webhook/3e8078fc-ccad-4077-b8e5-0feee66011b8@7250d88b-4b68-4529-be44-d59a2d8a6f94/IncomingWebhook/73d1849041d94801918aa6cf56912aab/c5ba7b76-89f5-4d7d-94c8-575131f6c59d --notificationtype problem --hostalias testing --hostaddress 192.168.168.1 --servicedesc "tsend" --servicestate "OK" --serviceoutput "TEsing Output"


#OPT_HN="testing.dur.fdqn"
#OPT_HS="DOWN"
#OPT_SN="Disk SMART - /dev/sda"
#OPT_NT="PROBLEM"
#OPT_SS="CRITICAL"
#OPT_OUTP="CHECK_NRPE STATE CRITICAL: Socket timeout after 10 seconds."

function get_colour() {
  case $1 in
    "OK")
      COLOUR="008000"
      ;;
    "WARNING")
      COLOUR="ffff00"
      ;;
    "UNKNOWN")
      COLOUR="ffff00"
      ;;
    "CRITICAL")
      COLOUR="ff0000"
      ;;
    "UP")
      COLOUR="008000"
      ;;
    "DOWN")
      COLOUR="ff0000"
      ;;
    "UNREACHABLE")
      COLOUR="ffff00"
      ;;
    *)
      COLOUR="ff8700"
      ;;
  esac
}

if [[ -z "$1" ]]; then
    echo "No Arguments Supplied"
    echo "Check --usage for usaged details."
    exit 1
elif [ $1 = "-u" ] || [ $1 = "--help" ] || [ $1 = "--usage" ]; then
    echo "nagios_teams           A simple wrapper for MS Teams Notifications for Nagios."
    echo "Usage:"
    echo "--url                  WebHook URL"
    echo "   --help              Same as -u --usage"
    echo "-u --usage             This screen"
    exit 0
else
  while [[ $# -gt 1 ]]
  do
    key="$1"

    case $key in
      --url)
        HOOK_URL="$2"
        shift
        ;;
      --notificationtype)
        OPT_NT="$2"
        shift
        ;;
      --hostaddress)
        OPT_HA="$2"
        shift
        ;;
      --hostalias)
        OPT_HN="$2"
        shift
        ;;
      --hoststate)
        OPT_HS="$2"
        shift
        ;;
      --servicedesc)
        OPT_SN="$2"
        shift
        ;;
      --servicestate)
        OPT_ss="$2"
        shift
        ;;
      --hostoutput|--serviceoutput)
        OPT_OUTP="$2"
        shift
        ;;
      *)
        echo "Wrong Arguments Supplied."
        echo "Check --usage for usaged details."
        exit 1
        ;;
    esac
    shift
  done

  # Use Host Address is Not Alias Provided
  if [[ -z $OPT_HN ]]; then
    OPT_HN=$OPT_HA
  fi

  TITLE=$OPT_NT": "$OPT_HN
  if [[ ! -z $OPT_HS ]]; then
    TITLE=$TITLE" "$OPT_HS
    get_colour $OPT_HS
  elif [[ ! -z $OPT_SN ]]; then
    TITLE=$TITLE" "$OPT_SN" "$OPT_SS
    get_colour $OPT_SS
  fi
  TEXT=$OPT_OUTP

  curl -H "Content-Type: application/json" -d "{\"title\": \"$TITLE\", \"text\": \"$TEXT\",\"themeColor\": \"$COLOUR\"}" $HOOK_URL >/dev/null 2>&1

fi
