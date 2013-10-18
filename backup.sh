#!/bin/bash

# What folders should be backupped?
declare -a what_to_backup=('/var/www/');

# Path where the backup and the backup folders should be stored
BACKUP_PATH="/root/backup/"
# Name of the folders to store the backups in
SQL_FOLDERNAME="sqldata"
DATA_FOLDERNAME="webdata"

BACKUP_MYSQL="1"
# MySql login information
MYSQL_USER=""
MYSQL_PASSWORD=""



NOW=$(date +"%d-%m-%Y")
for flag in "$@"
do
	if [ "$flag" == "-o" ]; then
		FLAG_OVERWRITE="1"
	fi

	if [ "$flag" == "-v" ]; then
		FLAG_VERBOSE="1"
	fi
done

FREE_DISCSPACE=`df / -h | awk '{ print $4 }' | tail -n 1 | cut -d "G" -f1`

# If discspace is lower than 15 GB, abort
if [[ $FREE_DISCSPACE -lt 15 ]]; then
	echo "Discspace is low! ( Less than 15 GB free. ) Backup aborted."
	exit
fi

if [ ! -d "$BACKUP_PATH/$SQL_FOLDERNAME" ]; then
	mkdir $BACKUP_PATH/$SQL_FOLDERNAME > /dev/null
	if [ $? -gt 0 ]; then
	    echo "Error while creating folder $BACKUP_PATH/$SQL_FOLDERNAME. Aborting."
	    exit
	fi
fi

if [ ! -d "$BACKUP_PATH/$DATA_FOLDERNAME" ]; then
	mkdir $BACKUP_PATH/$DATA_FOLDERNAME
	if [ $? -gt 0 ]; then
	    echo "Error while creating folder $BACKUP_PATH/$DATA_FOLDERNAME. Aborting."
	    exit
	fi
fi

cd $BACKUP_PATH/$SQL_FOLDERNAME/

if [ "$BACKUP_MYSQL" == "1" ]; then
	if [ ! -f ./database_backup.$NOW.tgz ] || [ "$FLAG_OVERWRITE" == "1" ]; then
		echo "Dumping all MySql-Databases..."
		mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --opt --all-databases > ./databases.sql
		echo "Done. Packing..."
		tar -zcvf database_backup.$NOW.tgz *.sql 
		echo "Done. Removing unpacked dump..."
		rm -f *.sql
		echo "Done. MySql-Backup finished into database_backup.$NOW.tgz ."
	else
		echo "Database backup for date $NOW already exists, skipping."
	fi
fi


cd $BACKUP_PATH/$DATA_FOLDERNAME/

DIRECTORY=$NOW

if [ ! -d "$DIRECTORY" ]; then
	mkdir $DIRECTORY
fi

cd ./$DIRECTORY/

for i in "${what_to_backup[@]}"
do	
	SPLIT=$(echo $i | tr "/" "\n")
	for x in $SPLIT
	do
		LAST=$x
	done

	if [ -d "$i" ]; then
		if [ ! -f ./$LAST.$NOW.tgz ] || [ "$FLAG_OVERWRITE" == "1" ]; then
			echo "Copying files from $i for packing..."
			cp -r $i ./
			echo "Done. Packing files..."
			tar -zcvf $LAST.$NOW.tgz ./$LAST >> $NOW.content.log
			echo "Done. Removing unpacked files..."
			rm -rf ./$LAST
			echo "Done. Folder backupped in $LAST.$NOW.tgz..."
		else
			echo "File $LAST.$NOW.tgz exists, skipping."
		fi
	else
		echo "Backup location $i wasn't found. Skipping."
	fi
done