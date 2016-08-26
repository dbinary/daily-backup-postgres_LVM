#!/bin/bash

STARTUPSCRIPT="/etc/init.d/postgresql"
LVM="/dev/Data/pgsql"
NEW_LVM="pgsql-snap"
LVMS="/dev/Data/${NEW_LVM}"
MNTP="/mnt/pgsql"
BZ2FILE="pgsql-backup"
BACKUPDIR="/ITM/backups"

function rename_file {
    /usr/bin/logger -i -t $(basename $0) 'Renombrando Archivo de Backup Anterior'
    DATE=$(date --date="1 day ago" "+%F")
    /bin/mv ${BACKUPDIR}/${BZ2FILE}.tar.bz2 ${BACKUPDIR}/${BZ2FILE}-${DATE}.tar.bz2
}

function backup {
    /usr/bin/logger -i -t $(basename $0) 'Deteniendo Postgresql'
    ${STARTUPSCRIPT} stop
    /usr/bin/logger -i -t $(basename $0) 'Creando SNAPSHOT LVM'
    ### CREATE LVM SNAPSHOT ###
    /usr/sbin/lvm lvcreate -s -n ${NEW_LVM} -l 100%FREE ${LVM}
    if [ $? -eq 0 ]
    then
        ### STARTING POSTGRESQL ###
        /usr/bin/logger -i -t $(basename $0) 'Iniciando Postgresql'
        ${STARTUPSCRIPT} start
        ### MOUNT SNAPSHOT ###
        /usr/bin/logger -i -t $(basename $0) 'Montando Snapshot'
        /bin/mount ${LVMS} ${MNTP}
        if [ $? -eq 0 ]
        then
            rename_file
            ### CREATING BACKUP ###
            /usr/bin/logger -i -t $(basename $0) 'Creando Backup Postgresql'
            cd /mnt/
            /bin/tar -cjvf ${BACKUPDIR}/${BZ2FILE}.tar.bz2 pgsql
            if [ $? -eq 0 ]
            then
                ### UMOUNT SNAPSHOT ###
                /usr/bin/logger -i -t $(basename $0) 'Desmontando Snapshot'
                cd /tmp
                /bin/umount ${MNTP}
                ### REMOVE LVM SNAPSHOT ###
                /usr/bin/logger -i -t $(basename $0) 'Eliminando SNAPSHOT LVM'
                /usr/sbin/lvm lvremove -f ${LVMS}
            else
                /usr/bin/logger -i -t $(basename $0) 'Error al crear archivo bz2'
            fi
        else
            /usr/bin/logger -i -t $(basename $0) 'Error al montar Snapshot'
        fi
    else
        /usr/bin/logger -i -t $(basename $0) 'Error al crear Snapshot LVM'
    fi
}

### MAIN PROGRAM ###
/usr/bin/logger -i -t $(basename $0) 'Iniciando Proceso de backup Postgresql'
cd ${BACKUPDIR}
if [ $? -eq 0 ]
then
    backup
else
    /usr/bin/logger -i -t $(basename $0) "directory ${BACKUPDIR} doesn't exists"
    exit 1
fi
