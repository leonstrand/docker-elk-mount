#!/bin/bash

# leon.strand@medeanalytics.com


# set date for use with /etc/fstab backup
date=$(date '+%Y-%m-%d_%H:%M:%S.%N')

# cifs username and password in file named credentials.cifs in same directory as this script
if [ -f $(dirname $0)/credentials.cifs ]; then
  if [ -s $(dirname $0)/credentials.cifs ]; then
    cifs_username=$(grep username $(dirname $0)/credentials.cifs | awk '{print $NF}')
    cifs_password=$(grep password $(dirname $0)/credentials.cifs | awk '{print $NF}')
  else
    echo $0: fatal: credentials file has no size: $(dirname $0)/credentials.cifs
    exit 1
  fi
else
  echo $0: fatal: required credentials file not found: $(dirname $0)/credentials.cifs
  exit 1
fi
if [ -z "$cifs_username" ]; then
  echo $0: fatal: unable to determine cifs username from credentials file $(dirname $0)/credentials.cifs
  exit 1
fi
if [ -z "$cifs_password" ]; then
  echo $0: fatal: unable to determine cifs password from credentials file $(dirname $0)/credentials.cifs
  exit 1
fi

# stage
#SACWEBV401
#SACWEBV402
#SACAPPV203
#SACAPPV204
#SACAPPV205
#SACAPPV206
#SACAPPV207

# uat
#SACUATWEBV201
#SACUATWEBV202
#SACUATAPPV201
#SACUATAPPV202
#SACUATAPPV203
#SACUATAPPV204
#SACUATAPPV205

# uat2
#PAIWEBV005
#PAIWEBV006
#PAIAPPV115
#PAIAPPV116

# prod
#PAIAPPV141
#PAIAPPV141
#PAIAPPV142
#PAIAPPV143
#PAIAPPV144
#PAIAPPV145
#PAIAPPMV131
#PAIAPPMV132
#PAIAPPMV133
#PAIAPPMV134
#PAIAPPMV135
#SACWEBV121
#SACWEBV122
#SACWEBV123
#PAIWEBV001
#PAIWEBV002
#PAIWEBV003
#PAIWEBV004


if [ -z "$1" ]; then
  hosts='
    SACWEBV401
    SACWEBV402
    SACAPPV203
    SACAPPV204
    SACAPPV205
    SACAPPV206
    SACAPPV207
    SACUATWEBV201
    SACUATWEBV202
    SACUATAPPV201
    SACUATAPPV202
    SACUATAPPV203
    SACUATAPPV204
    SACUATAPPV205
    PAIWEBV005
    PAIWEBV006
    PAIAPPV115
    PAIAPPV116
    PAIAPPV141
    PAIAPPV142
    PAIAPPV143
    PAIAPPV144
    PAIAPPV145
    PAIAPPMV131
    PAIAPPMV132
    PAIAPPMV133
    PAIAPPMV134
    PAIAPPMV135
    SACWEBV121
    SACWEBV122
    SACWEBV123
    PAIWEBV001
    PAIWEBV002
    PAIWEBV003
    PAIWEBV004
  '
else
  hosts="$@"
fi
directories_common='
PAI_Conifer/Logs
PAI_FCW/Logs
'
directories_app='
pai_reports_conifer/Logs
rulesengine_conifer/logs
'
directories_web='
PAI_Reports_Conifer/Logs
RulesEngine_Conifer/Logs
'


# create backup of /etc/fstab
fstab_before=$(dirname $0)/backup/fstab.${date}.a
fstab_after=$(dirname $0)/backup/fstab.${date}.b
echo #verbose
echo #verbose
echo $0: creating backup of /etc/fstab as $fstab_before in case changes are made
cp -v /etc/fstab $fstab_before

for host in $hosts; do
  echo #verbose
  echo #verbose
  echo $0: $host #verbose
  ip=''
  case $host in
    SACWEB*|SACUATWEB*|PAIWEBV00[1234])
      ip=`dig $host.medeanalytics.local +short | sort -V | head -1`
    ;;
    *)
      ip=`dig $host.medeanalytics.local +noall +answer | tail -1 | awk '{print $NF}'`
    ;;
  esac
  if [ -n "$ip" ]; then
    echo $0: $ip #verbose
    prefix='Mede/Mede'
    case $host in
    PAIWEBV00[1234])
        directories="
          pai_conifer/logs
          PAI_FCW/Logs
        "
        prefix='Mede/mede'
      ;;
      SACWEBV121|SACWEBV122|SACWEBV123)
        directories="
          PAI_Conifer/Logs
          PAI_FCW/Logs
          PAI_Reports_Conifer/Logs
          RulesEngine_Conifer/Logs
        "
      ;;
      PAIAPPV141|PAIAPPV142|PAIAPPV143|PAIAPPV144|PAIAPPV145|PAIAPPMV131|PAIAPPMV132|PAIAPPMV133|PAIAPPMV134|PAIAPPMV135)
        directories="
          PAI/logs
          PAI_FCW/Logs
          PAI_Reports/Logs
          PAI_RulesEngine/Logs
        "
      ;;
      SACWEB*)
        directories="
          $directories_common
          $directories_web
        "
      ;;
      SACAPP*)
        directories="
          $directories_common
          $directories_app
        "
      ;;
      SACUATWEB*)
        directories="
          PAI/logs
          PAI_Reports/logs
          PAI_FCW/Logs
        "
      ;;
      SACUATAPP*)
        directories="
          PAI/logs
          pai_fcw/Logs
          PAI_Reports/logs
          RulesEngine/logs
        "
      ;;
      PAIWEB*)
        directories="
          fcw/logs
          PAI_Conifer/Logs
          PAI_Reports_Conifer/Logs
        "
      ;;
      PAIAPP*)
        directories="
          fcw/logs
          PAI_Conifer/Logs
          $directories_web
        "
      ;;
      *)
        echo $0: host $host unsupported, skipping... #verbose
        continue
      ;;
    esac
    for directory in $directories; do
      echo
      echo $0: directory: $directory #verbose #verbose
      echo $0: ls -d /pai-logs/$host/$directory #verbose
      ls -d /pai-logs/$host/$directory #verbose
      if ! [ -d /pai-logs/$host/$directory ]; then
        echo sudo mkdir -vp /pai-logs/$host/$directory #verbose
        sudo mkdir -vp /pai-logs/$host/$directory
      fi
      if ! grep -q '^\s*//'$ip'/'$prefix'/'$directory'\s*/pai-logs/'$host'/'$directory'/\s*cifs\s*username='$cifs_username',password='$cifs_password',ro\s*0\s*0$' /etc/fstab; then
        echo $0: did not find mount for $host and $directory in /etc/fstab, adding... #verbose
        #//x.x.x.x/Mede/Mede/PAI_Conifer/Logs /pai-logs/host/ cifs username=****,password=****,ro 0 0
        echo echo \'//$ip/$prefix/$directory /pai-logs/$host/$directory/ cifs username=$cifs_username,password=$cifs_password,ro 0 0\' \| sudo tee -a /etc/fstab #verbose
        echo '//'$ip'/'$prefix'/'$directory' /pai-logs/'$host'/'$directory'/ cifs username='$cifs_username',password='$cifs_password',ro 0 0' | sudo tee -a /etc/fstab
        echo sudo mount -v /pai-logs/$host/$directory/ #verbose
        sudo mount -v /pai-logs/$host/$directory/
      else
        echo $0: found mount for $host and $directory in /etc/fstab #verbose
      fi
    done
  else
    echo $0: error: could not determine ip address for $host, skipping... #verbose
    continue
  fi
done
echo #verbose
echo #verbose
echo $0: checking for changes to /etc/fstab
if ! diff /etc/fstab $fstab_before; then
  echo $0: /etc/fstab changed, creating backup $fstab_after
  cp -v /etc/fstab $fstab_after
else
  echo $0: /etc/fstab not changed, removing unnecessary backup $fstab_before
  rm -v $fstab_before
fi
echo #verbose
echo #verbose
