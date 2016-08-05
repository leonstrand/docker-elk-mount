#!/bin/bash

# leon.strand@medeanalytics.com


# cifs username and password in file named credentials.cifs in same directory as this script
cifs_username=$(grep username $(dirname $0)/credentials.cifs | awk '{print $NF}')
cifs_password=$(grep password $(dirname $0)/credentials.cifs | awk '{print $NF}')

# static declaration of ip addresses for web servers because dns resolution returns multiple ip addresses
declare -A web_servers
web_servers=(
["SACWEBV401"]="10.153.2.91"
["SACWEBV402"]="10.153.2.92"
)
if [ -z "$1" ]; then
  hosts='
    SACAPPV203
    SACAPPV204
    SACAPPV205
    SACAPPV206
    SACAPPV207
    SACWEBV401
    SACWEBV402
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

for host in $hosts; do
  echo #verbose
  echo #verbose
  echo $0: $host #verbose
  ip=''
  case $host in
    *APP*)
      ip=`dig $host.medeanalytics.local +noall +answer | tail -1 | awk '{print $NF}'`
    ;;
    SACWEB*)
      ip=${web_servers["$host"]}
    ;;
  esac
  if [ -n "$ip" ]; then
    echo $0: $ip #verbose
    case $host in
      SACAPP*)
        directories="
          $directories_common
          $directories_app
        "
      ;;
      SACWEB*)
        directories="
          $directories_common
          $directories_web
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
      PAIAPP*)
        directories="
          fcw/logs
          PAI_Conifer/Logs
          $directories_web
        "
      ;;
      *)
        echo $0: host $host unsupported, skipping... #verbose
        break
      ;;
    esac
    for directory in $directories; do
      echo
      echo $0: directory: $directory #verbose #verbose
      echo $0: ls -d /pai-logs/$host/$directory #verbose
      ls -d /pai-logs/$host/$directory #verbose
      if ! [ -d /pai-logs/$host/$directory ]; then
        echo sudo mkdir -vp /pai-logs/$host/$directory #verbose
        ##sudo mkdir -vp /pai-logs/$host/$directory
      fi
      if ! grep -q '^\s*//'$ip'/Mede/Mede/'$directory'\s*/pai-logs/'$host'/'$directory'/\s*cifs\s*username='$cifs_username',password='$cifs_password',ro\s*0\s*0$' /etc/fstab; then
        echo $0: did not find mount for $host and $directory in /etc/fstab, adding... #verbose
        #//x.x.x.x/Mede/Mede/PAI_Conifer/Logs /pai-logs/host/ cifs username=****,password=****,ro 0 0
        echo echo \'//$ip/Mede/Mede/$directory /pai-logs/$host/$directory/ cifs username=$cifs_username,password=$cifs_password,ro 0 0\' \| sudo tee -a /etc/fstab #verbose
        ##echo '//'$ip'/Mede/Mede/'$directory' /pai-logs/'$host'/'$directory'/ cifs username='$cifs_username',password='$cifs_password',ro 0 0' | sudo tee -a /etc/fstab
        echo sudo mount -v /pai-logs/$host/$directory/ #verbose
        ##sudo mount -v /pai-logs/$host/$directory/
      else
        echo $0: found mount for $host and $directory in /etc/fstab #verbose
      fi
    done
  else
    echo $0: error: could not determine ip address for $host, skipping... #verbose
    break
  fi
done
echo #verbose
echo #verbose
