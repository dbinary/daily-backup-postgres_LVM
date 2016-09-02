# daily-backup-postgres
script for automatically backup a postgresql database based on LVM

### Requirements:
* Postgresql installed in LVM scheme
* NFS or SMB shared storage
* autofs package

### Procedure:
* Verify autofs mount point is accesible
* Stop postgresql service
* Create LVM snapshot
* Start postgresql service ( for minimal downtime )
* Mount snapshot
* Create a tar.bz2 file from mount point snapshot to autofs mount
* Delete LVM snapshot

### Setup for script:
* cd /usr/local/sbin/
* git clone https://github.com/dbinary/daily-backup-postgresql.git
* chmod +x backup_db_postgresql.sh
* edit script
    * `vim backup_db_postgresql.sh`
    * and config this variables
    ```bash
    STARTUPSCRIPT="/etc/init.d/postgresql" # startup script for init postgresql
    LVM="" # path of LV to backup i.e. /dev/VolGroup01/postgresql
    NEW_LVM="" # name for snapshot LV  i.e. postgresql-snap
    LVMS="" # path of new LV i.e. /dev/VolGroup01/${NEW_LVM}
    MNTP="/mnt/pgsql" # path for mount snapshot LVM (recommended this)
    BZ2FILE="pgsql-backup" # name for bz2 file backup
    BACKUPDIR="/PATH/backups" # remote dir  for store backup`
    ```
* mkdir /var/log/backupdb
* setup crontab
    * 00 02 * * * sh /usr/local/sbin/backup_db_postgresql.sh > /var/log/backupdb/backupdb.log 2> /var/log/backupdb/error-backupdb.log

### Setup autofs
* RHEL, CENTOS 7
    * Create file in /etc/auto.master.d/
    * `vim backup.autofs`
        * content for file `/- /etc/auto.backup`
    * now edit /etc/auto.backup
    * `vim /etc/auto.backup`
        * add content for NFS: 
            * `/Backup -rw,sync <IP>:/BackupsKVM`
        * add content for SMB: 
            * `/Backup -fstype=cifs,rw,credentials=/etc/credentials.backup ://<IP>/backups/DIARIOS`
            * where credentials=/etc/credentials.backup 
            ```bash
               username=userbackup
               password=passworduserbackup
               domain=ifhaveone
              ```


