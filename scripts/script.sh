#!/bin/bash
#
# update OS, create all hana partitions depending on input parameter from bicep template and install SAP HANA
# cat customscript.sh | base64 -w0
#
set -x

HANAVER=${1}
HANASID=${2}
HANANUMBER=${3}
vmSize=${4}
Uri=${5}
sas=${6}
HANAUSR=${7}
HANAPWD=${8}

function log()
{
  message=$@
  echo "$message"
  echo "$(date -Iseconds): $message" >> /tmp/hanacustomscript
}

function setEnv()
{
  #decode hana version parameter
  HANAVER=${HANAVER^^}
  if [ "${HANAVER}" = "2.0 SPS01 REV10 (51052030)" ]; then hanapackage="51052030"; fi
  if [ "${HANAVER}" = "2.0 SPS02 REV20 (51052325)" ]; then hanapackage="51052325"; fi
  if [ "${HANAVER}" = "2.0 SPS03 REV30 (51053061)" ]; then hanapackage="51053061"; fi
  if [ "${HANAVER}" = "2.0 SPS04 REV40 (51053787)" ]; then hanapackage="51053787"; fi
  if [ "${HANAVER}" = "2.0 SPS05 REV56" ]; then hanapackage="56"; fi
  if [ "${HANAVER}" = "2.0 SPS06 REV60" ]; then hanapackage="60"; fi

   
  #get the VM size via the instance api
  VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

  extrasmallVMs=("Standard_DS14_v2" "Standard_E16s_v3" "Standard_E20ds_v4")
  smallVMs=("Standard_M32ts" "Standard_E32s_v3" "Standard_M32ls")
  mediumVMs=("Standard_E48ds_v4" "Standard_E64s_v3" "Standard_M64ls")
  largeVMs=("Standard_M32dms_v2" "Standard_M64s")
  extralargeVMs=("Standard_M64ms" "Standard_M128s" "Standard_M208s_v2" "Standard_M128ms")

}

function installPackages()
{
  log "installPackages start"

  # to handle issues with SMT registration:
  #rm /etc/SUSEConnect
  #rm -f /etc/zypp/{repos,services,credentials}.d/*
  #rm -f /usr/lib/zypp/plugins/services/*
  #sed -i '/^# Added by SMT reg/,+1d' /etc/hosts
  #/usr/sbin/registercloudguest --force-new
  
  zypper in -y glibc-2.22-51.6 systemd-228-142.1 unrar sapconf saptune
  zypper in -t pattern -y sap-hana
  
  saptune solution apply HANA
  saptune daemon start

  log "installPackages done"
}

function enableSwap()
{
  log "enableSwap start"
  echo $Uri >> /tmp/url.txt

  cp -f /etc/waagent.conf /etc/waagent.conf.orig
  sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
  sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=2048/g"
  cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
  cp -f /etc/waagent.conf.new /etc/waagent.conf

  #don't restart waagent, as this will kill the custom script.
  #service waagent restart

  log "enableSwap done" 
}

function createVolumes()
{
  log "createVolumes start"

  mkdir /etc/systemd/login.conf.d
  mkdir /hana
  mkdir /hana/data
  mkdir /hana/log
  mkdir /hana/shared
  mkdir /hana/backup
  mkdir /usr/sap

  pvcreate -ff -y /dev/disk/azure/scsi1/lun0   
  pvcreate -ff -y /dev/disk/azure/scsi1/lun1
  pvcreate -ff -y /dev/disk/azure/scsi1/lun2
  pvcreate -ff -y /dev/disk/azure/scsi1/lun3
  pvcreate -ff -y /dev/disk/azure/scsi1/lun4
  pvcreate -ff -y /dev/disk/azure/scsi1/lun5
  pvcreate -ff -y /dev/disk/azure/scsi1/lun6
  pvcreate -ff -y /dev/disk/azure/scsi1/lun7
  
  #shared volume creation
  sharedvglun="/dev/disk/azure/scsi1/lun0"
  vgcreate sharedvg $sharedvglun
  lvcreate -l 100%FREE -n sharedlv sharedvg 
  mkfs.xfs /dev/sharedvg/sharedlv 
  
  #usr/sap volume creation
  usrsapvglun="/dev/disk/azure/scsi1/lun1"
  vgcreate usrsapvg $usrsapvglun
  lvcreate -l 100%FREE -n usrsaplv usrsapvg
  mkfs.xfs /dev/usrsapvg/usrsaplv

  #backup volume creation
  backupvglun="/dev/disk/azure/scsi1/lun2"
  vgcreate backupvg $backupvglun
  lvcreate -l 100%FREE -n backuplv backupvg 
  mkfs.xfs /dev/backupvg/backuplv


  if [  " ${extrasmallVMs[*]} " =~ " ${VMSIZE} " ] ; then
    
    #data volume creation
    datavg1lun="/dev/disk/azure/scsi1/lun3"
    datavg2lun="/dev/disk/azure/scsi1/lun4"
    datavg3lun="/dev/disk/azure/scsi1/lun5"
    vgcreate datavg $datavg1lun $datavg2lun $datavg3lun
    PHYSVOLUMES=3
    STRIPESIZE=256
    lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n datalv datavg

    #log volume creation
    logvg1lun="/dev/disk/azure/scsi1/lun6"
    logvg2lun="/dev/disk/azure/scsi1/lun7"
    vgcreate logvg $logvg1lun $logvg2lun
    PHYSVOLUMES=2
    STRIPESIZE=64
    lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv logvg    

  else

    pvcreate -ff -y /dev/disk/azure/scsi1/lun8
    pvcreate -ff -y /dev/disk/azure/scsi1/lun9
  
    #data volume creation
    datavg1lun="/dev/disk/azure/scsi1/lun3"
    datavg2lun="/dev/disk/azure/scsi1/lun4"
    datavg3lun="/dev/disk/azure/scsi1/lun5"
    datavg4lun="/dev/disk/azure/scsi1/lun6"
    vgcreate datavg $datavg1lun $datavg2lun $datavg3lun $datavg4lun
    PHYSVOLUMES=4
    STRIPESIZE=256
    lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n datalv datavg

    #log volume creation
    logvg1lun="/dev/disk/azure/scsi1/lun7"
    logvg2lun="/dev/disk/azure/scsi1/lun8"
    logvg3lun="/dev/disk/azure/scsi1/lun9"
    vgcreate logvg $logvg1lun $logvg2lun
    PHYSVOLUMES=3
    STRIPESIZE=64
    lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv logvg

  fi  

  mkfs.xfs /dev/datavg/datalv
  mkfs.xfs /dev/logvg/loglv

  # mounting 
  mount -t xfs /dev/sharedvg/sharedlv /hana/shared
  mount -t xfs /dev/usrsapvg/usrsaplv /usr/sap
  mount -t xfs /dev/backupvg/backuplv /hana/backup 
  mount -t xfs /dev/datavg/datalv /hana/data
  mount -t xfs /dev/logvg/loglv /hana/log

  echo "/dev/mapper/sharedvg-sharedlv /hana/shared xfs defaults 0 0" >> /etc/fstab
  echo "/dev/mapper/usrsapvg-usrsaplv /usr/sap xfs defaults 0 0" >> /etc/fstab
  echo "/dev/mapper/backupvg-backuplv /hana/backup xfs defaults 0 0" >> /etc/fstab
  echo "/dev/mapper/datavg-datalv /hana/data xfs defaults 0 0" >> /etc/fstab 
  echo "/dev/mapper/logvg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab

  log "createVolumes done"
}

function azcopy()
{
  log "azcopy start"
  
  cd /usr/
  
  wget -O azcopy.tar.gz https://aka.ms/downloadazcopy-v10-linux 
	tar -xf azcopy.tar.gz
	export PATH=$PATH:/usr/azcopy_linux_amd64_10.11.0

  log "azcopy done"
}

function prepareSAPBins()
{
  log "prepareSAPBins start"

  SAPBITSDIR="/hana/data/sapbits"

  if [ ! -d $SAPBITSDIR ]
  then
    mkdir $SAPBITSDIR
  fi

  cd $SAPBITSDIR
  mkdir ${hanapackage}
  cd ${hanapackage}

  if [ "${hanapackage}" = "51053787" ]
  then 
    /usr/bin/wget -o ${hanapackage}.ZIP --quiet $Uri/${hanapackage}.ZIP${sas}
    unzip ${hanapackage}.ZIP  
  else
    if [ "${hanapackage}" = "56" ] || [ "${hanapackage}" = "60" ]
    then
      /usr/bin/wget -O SAPCAR --quiet $Uri/SAPCAR${sas}
      /usr/bin/wget -O IMDB_SERVER20_0${hanapackage}_0-80002031.SAR --quiet $Uri/IMDB_SERVER20_0${hanapackage}_0-80002031.SAR${sas}

      chmod 777 SAPCAR
      ./SAPCAR -xvf IMDB_SERVER20_0${hanapackage}_0-80002031.SAR
      ./SAPCAR -xvf IMDB_SERVER20_0${hanapackage}_0-80002031.SAR SIGNATURE.SMF -manifest SIGNATURE.SMF
    else
      /usr/bin/wget -O ${hanapackage}_part1.exe --quiet $Uri/${hanapackage}_part1.exe${sas}
      /usr/bin/wget -O ${hanapackage}_part2.rar --quiet $Uri/${hanapackage}_part2.rar${sas}
      /usr/bin/wget -O ${hanapackage}_part2.rar --quiet $Uri/${hanapackage}_part3.rar${sas}
      /usr/bin/wget -O ${hanapackage}_part2.rar --quiet $Uri/${hanapackage}_part4.rar${sas}
      unrar  -o- x ${hanapackage}_part1.exe
    fi
  fi

  log "prepareSAPBins done"
}

function installHANA()
{
  log "installHANA start"

  cd $SAPBITSDIR
  /usr/bin/wget --quiet "https://raw.githubusercontent.com/1lomeno3/sap-hana-bicep/main/scripts/hdbinst.cfg"

  myhost=`hostname`
  sedcmd1="s/REPLACE-WITH-HOSTNAME/$myhost/g"
  #sedcmd2="s/\/hana\/shared\/sapbits\/51052325/\/hana\/data\/sapbits\/${hanapackage}/g"
  sedcmd3="s/root_user=root/root_user=$HANAUSR/g"
  sedcmd4="s/AweS0me@PW/$HANAPWD/g"
  sedcmd5="s/sid=H10/sid=$HANASID/g"
  sedcmd6="s/number=00/number=$HANANUMBER/g"
  cat hdbinst.cfg | sed $sedcmd1 | sed $sedcmd2 | sed $sedcmd3 | sed $sedcmd4 | sed $sedcmd5 | sed $sedcmd6 > hdbinst-local.cfg
  
  #put host entry in hosts file using instance metadata api
  VMIPADDR=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text"`
  VMNAME=`hostname`
  
  echo $VMIPADDR $VMNAME >> /etc/hosts
  
  if [ "${hanapackage}" = "56" ] || [ "${hanapackage}" = "60" ]
  then
    /hana/data/sapbits/${hanapackage}/SAP_HANA_DATABASE/hdblcm -b --configfile /hana/data/sapbits/hdbinst-local.cfg
  else
    /hana/data/sapbits/${hanapackage}/DATA_UNITS/HDB_LCM_LINUX_X86_64/hdblcm -b --configfile /hana/data/sapbits/hdbinst-local.cfg
  fi

  log "installHANA done"
}

function enableBackup()
{
  log "enableBackup start"

  cd /tmp
  /usr/bin/wget --quiet -O backupscript.sh https://aka.ms/ScriptForPermsOnHANA?clcid=0x0409
  chmod 777 backupscript.sh

  SIDADM=${HANASID,,}adm
  SYSTEMDB=${HANASID}SYSTEMDB
  HANAPORT=3${HANANUMBER}13

  su - $SIDADM -c "hdbuserstore set $SYSTEMDB localhost:$HANAPORT SYSTEM $HANAPWD"

  # it will restart waagent :(
  # /tmp/backupscript.sh -sk $SYSTEMDB

  log "enableBackup done"
}


################
# ### MAIN ### #
################

log "custom script start"

setEnv
installPackages
enableSwap
createVolumes
azcopy
prepareSAPBins
installHANA
enableBackup

log "custom script done"

exit
