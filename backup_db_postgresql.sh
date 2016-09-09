#!/bin/bash

# MIT License
#
# Copyright (c) 2016 Luis Perez
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

STARTUPSCRIPT="/etc/init.d/postgresql" # startup script for init postgresql
LVM="" # path of LV to backup i.e. /dev/VolGroup01/postgresql
NEW_LVM="" # name for snapshot LV  i.e. postgresql-snap
LVMS="" # path of new LV i.e. /dev/VolGroup01/${NEW_LVM}
MNTP="/mnt/pgsql" # path for mount snapshot LVM (recommended this)
BZ2FILE="pgsql-backup" # name for bz2 file backup
BACKUPDIR="/PATH/backups" # remote dir  for store backup

function rename_file {
    /usr/bin/logger -i -t $(basename $0) 'Renombrando Archivo de Backup Anterior'
    DATE=$(date --date="1 day ago" "+%F")
    /bin/mv ${BACKUPDIR}/${BZ2FILE}.tar.bz2 ${BACKUPDIR}/${BZ2FILE}-${DATE}.tar.bz2
}

function retention_policy {
    find ${BACKUPDIR} -name "pgsql-backup*" -mtime +7 -exec rm -rf {} \;
}

function wait_service {
    while true; 
    do
        process_id=$(pgrep postmaster)
        if [ $? -eq 0 ]
        then
            sleep 10
        else
            break
        fi
    done
}

function backup {
    /usr/bin/logger -i -t $(basename $0) 'Creando SNAPSHOT LVM'
    ### CREATE LVM SNAPSHOT ###
    /usr/sbin/lvm lvcreate -s -n ${NEW_LVM} -l 100%FREE ${LVM}
    if [ $? -eq 0 ]
    then
        ### STARTING POSTGRESQL ###
        /usr/bin/logger -i -t $(basename $0) 'Iniciando Postgresql'
        ${STARTUPSCRIPT} start
        if [ $? -eq 0 ]
        then
            ### MOUNT SNAPSHOT ###
            /usr/bin/logger -i -t $(basename $0) 'Montando Snapshot'
            /bin/mount ${LVMS} ${MNTP}
            if [ $? -eq 0 ]
            then
                rename_file
                ### CREATING BACKUP ###
                /usr/bin/logger -i -t $(basename $0) 'Creando Backup Postgresql'
                /usr/bin/logger -i -t $(basename $0) 'Se excluye el directorio pg_log'
                cd /mnt/
                /bin/tar -cjvf ${BACKUPDIR}/${BZ2FILE}.tar.bz2 --exclude='pg_log' pgsql
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
                    return 1
                fi
            else
                /usr/bin/logger -i -t $(basename $0) 'Error al montar Snapshot'
                return 1
            fi
        else
            /usr/bin/logger -i -t $(basename $0) 'Error al iniciar servicio Postgresql'
        fi
    else
        /usr/bin/logger -i -t $(basename $0) 'Error al crear Snapshot LVM'
        return 1
    fi
}

### MAIN PROGRAM ###
/usr/bin/logger -i -t $(basename $0) 'Iniciando Proceso de backup Postgresql'
cd ${BACKUPDIR}
if [ $? -eq 0 ]
then
    /usr/bin/logger -i -t $(basename $0) 'Deteniendo Postgresql'
    ${STARTUPSCRIPT} stop
    /usr/bin/logger -i -t $(basename $0) "Ejecutando ${STARTUPSCRIPT} stop"
    wait_service
    backup
    if [ $? -eq 0 ]
    then
        /usr/bin/logger -i -t $(basename $0) 'Proceso de backup Postgresql Finalizado con Exito'
    else
        /usr/bin/logger -i -t $(basename $0) 'Proceso de backup Postgresql Finalizado con Errores'
    fi
else
    /usr/bin/logger -i -t $(basename $0) "directory ${BACKUPDIR} doesn't exists"
    exit 1
fi
