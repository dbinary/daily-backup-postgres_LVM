# daily-backup-postgres
script for automatically backup a postgresql database based on LVM

Setup:
* cd /usr/local/sbin/
* git clone [ repo ](https://github.com/dbinary/daily-backup-postgresql.git)
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
BACKUPDIR="/ITM/backups" # remote dir  for store backup`
```
* mkdir /var/log/backupdb
* setup crontab
    * 00 02 * * * sh /usr/local/sbin/backup_db_postgresql.sh > /var/log/backupdb/backupdb.log 2> /var/log/backupdb/error-backupdb.log
