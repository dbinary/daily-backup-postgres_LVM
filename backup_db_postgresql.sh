#!/bin/bash

USRSMB='user'
PASSSMB='password'
DOMAINSMB='Domain'
REMOTESMB='192.168.13.15/backups/DIARIOS'
MNTSMB='/backups'

STARTUPSCRIPT="/etc/init.d/postgresql"
LVM="/dev/Data/pgsql"
NLVMS="pgsql-snap"
LVMS="/dev/Data/${NLVMS}"
MNTP="/mnt/pgsql"
BZ2FILE="pgsql-backup"
BACKUPDIR="/backup"

function deletefile {
    /usr/bin/logger -i -t $(basename $0) 'Eliminando Archivo de Backup anterior'
    /bin/rm -rf ${BACKUPDIR}/${BZ2FILE}.tar.bz2
}

function exists {
if [ -d "$1" ]; then
    $2
else
    /bin/mkdir $1
    $2
fi
}
function backup {
    /usr/bin/logger -i -t $(basename $0) 'Creando SNAPSHOT LVM'
    ### CREATE LVM SNAPSHOT ###
    /usr/sbin/lvm lvcreate -s -n ${NLVMS} -l 100%FREE ${LVM}
    if [ $? -eq 0 ]
    then
        ### STARTING POSTGRESQL ###
        /usr/bin/logger -i -t $(basename $0) 'Iniciando Postgresql'
        ${STARTUPSCRIPT} start
        ### MOUNT SNAPSHOT ###
        /usr/bin/logger -i -t $(basename $0) 'Montando Snapshot'
        /bin/mount ${LVMS} ${MNTP}
        ### ENTER DIRECTORY ###
        cd /mnt/
        deletefile
        ### CREATING BACKUP ###
        /usr/bin/logger -i -t $(basename $0) 'Creando Backup Postgresql'
        /bin/tar -cjvf ${BACKUPDIR}/${BZ2FILE}.tar.bz2 pgsql
    else
        /usr/bin/logger -i -t $(basename $0) 'Creando Backup Postgresql'
    fi
    ### UMOUNT SNAPSHOT ###
    /usr/bin/logger -i -t $(basename $0) 'Desmontando Snapshot'
    /bin/umount ${MNTP}
    ### REMOVE LVM SNAPSHOT ###
    /usr/bin/logger -i -t $(basename $0) 'Eliminando SNAPSHOT LVM'
    /usr/sbin/lvm lvremove -f ${LVMS}
    exists ${MNTSMB} movebk
}

function movebk {
    /usr/bin/logger -i -t $(basename $0) 'Montando Storage Remoto'
    /bin/mount -t cifs -o domain=${DOMAINSMB},user=${USRSMB},password=${PASSSMB} //${REMOTESMB} ${MNTSMB}
    if [ $? -eq 0]
    then
        /usr/bin/logger -i -t $(basename $0) 'Copiando archivo al Storage Remoto'
        /bin/cp ${BACKUPDIR}/${BZ2FILE}.tar.bz2 ${MNTSMB}${BZ2FILE}-$(date +%F).tar.bz2
        ### UMOUNT STORAGE ###
        /usr/bin/logger -i -t $(basename $0) 'Desmontando Storage Remoto'
        /bin/umount ${MNTSMB}
    else
        /usr/bin/logger -i -t $(basename $0) 'No se pudo montar el Storage Remoto'
    fi
}

/usr/bin/logger -i -t $(basename $0) 'Iniciando Proceso de backup Postgresql'
/usr/bin/logger -i -t $(basename $0) 'Deteniendo Postgresql'
### STOPPING DATABASE ###
${STARTUPSCRIPT} stop

exists ${MNTP} backup
