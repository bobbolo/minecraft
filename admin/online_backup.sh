#!/bin/bash

### daily on-line bakcup script.
### try to backup everything that is important without causing too much LAG (if possible)
### rsync data, dump database, tar and compress data, then upload to S3 bucket for safe keeping

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin

### directory where backup diretories are stored
BACKUPHOME="/home/backup/snapshots"
RSYNC_CURRENT="${BACKUPHOME}/current"

### date string for directory creation
DATESTR=`date '+%Y-%m-%d'`

BACKUPDIRPATH="${BACKUPHOME}/${DATESTR}"
##################################################################################
### Config section - Modify paths as needed

### directories in the /home/cfmain that we want to backup
### each of these will get their own tarball for easier management

BACKUPDIRS="jre1.8.0_161 minecraft_13 minecraft_14_beta"

##################################################################################
### Figure out if there is alreasy a backup diretory (generally there shouldn't be if this is
### ran once a day

if [ ! -d ${BACKUPDIRPATH} ]; then

  echo "`date` ### Crating directory for backups: ${BACKUPDIRPATH}"
  mkdir ${BACKUPDIRPATH}
fi

### Change to the directory path
cd ${BACKUPDIRPATH}

#exit;

### touch the toggle auto-save off file for MC PROD
echo "`date` ### shutting off auto-safe on MC PROD"

#sleep 90

### tarball up various Minecraft directories, we don't want to follow softlinks!!!
#we're NOT going to backup data from the ramdrive

for BDIR in ${BACKUPDIRS}
do
  echo "`date` ### Backing up via RSYNC: /home/cfmain/${BDIR} to: ${BACKUPDIRPATH}/${BDIR}.tar"
  #ionice -c3 tar -C /home/cfmain/ --exclude='backups/*' --one-file-system -cvf ${BACKUPDIRPATH}/${BDIR}.tar ${BDIR}
  ionice -c3 rsync -v -a -x -L  --ignore-errors --delete --exclude='backups/*' --exclude='world_storage/*' --exclude='orebfuscator_cache/*' /home/cfmain/${BDIR} ${RSYNC_CURRENT}
done

### tarball the WWW directory as well
echo "`date` ### Backup up: /var/www to: ${BACKUPDIRPATH}/www-html.tar"
#ionice -c3 tar -C /var/www --exclude='dynmap/tiles/*' -cvf ${BACKUPDIRPATH}/www-html.tar html
ionice -c3 rsync -v -a -x -L --delete --exclude='map/tiles/*' --exclude='map_beta/tiles/*' --exclude='admin/v1_worlds/*' /var/www ${RSYNC_CURRENT}

#echo "`date` ### Backing up: /home/cfdev to: ${BACKUPDIRPATH}/cfdev.tar"
#ionice -c3 tar -C /home/cfdev --one-file-system -cvf ${BACKUPDIRPATH}/cfdev.tar .
#ionice -c3 rsync -v -a -x -L --delete /home/cfdev ${RSYNC_CURRENT}

#echo "`date` ### Backing up: /home/xtf2 to: ${BACKUPDIRPATH}/xtf2.tar"
##ionice -c3 tar -C /home/xtf2 --one-file-system -cvf ${BACKUPDIRPATH}/xtf2.tar .
#ionice -c3 rsync -v -a -x -L --delete /home/xtf2 ${RSYNC_CURRENT}

### dump the database tables

echo "`date` ### Backing up databases."
DATABASELIST=`mysql -u '<db user here>' --password='<database password here>' -B -e 'show databases;' | perl -ne 'chomp($_); print qq{$_ };'`

for DB in ${DATABASELIST}
do

  echo "`date` ### Dumping table: ${DB} to: ${BACKUPDIRPATH}/${DB}.sql"
  mysqldump -u '<db user here>' --password='<database password here>' --skip-lock-tables ${DB} > ${BACKUPDIRPATH}/${DB}.sql

done


### Tarball all the directories in current, into the 'date' directory
echo "`date` ### Create compressed tarballs of each rsync directory structure in the 'current' directory"
(
  cd ${RSYNC_CURRENT} ;
  find * -type d -prune -a ! -name 'minecraft_v1' -exec bash -c 'echo "`date` ### Creating compressed tarball: $1" ; nice tar -cjf $2/$1.tar.bz2 $1 ' -- {} ${BACKUPDIRPATH} \;
)

### bzip2 all the files to save space
echo "`date` ### bzip-ing backup files"
#find /home/backup/snapshots -name '*.tar' -o -name '*.sql' | parallel -P 25% bzip2 -v {}

find /home/backup/snapshots/20* \( -name '*.tar' -o -name '*.sql' \) -exec du {} \; | sort -n | parallel -P 25% --colsep '\t' nice bzip2 -v {2} 2>&1

#bzip2 -v *.tar *.sql
echo "`date` ### sending backup files to s3"

cd ${BACKUPHOME}
#send compressed backup files to s3
nice s3cmd -c /root/.s3cfg --recursive --progress put $DATESTR s3://<S3 backup bucket name here>/backups/

echo "`date` ### Backup Script Complete"
