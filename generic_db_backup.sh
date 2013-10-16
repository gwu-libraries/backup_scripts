#!/bin/bash
#Usage: ./generic_db_backup.sh <DNS name> <DB type> <DB name> <destination> <username> <path to passfile> <retention time in days>
#Example ./generic_db_backup.sh library.gwu.edu psql archiviststoolkit /vol/backup someuser /path/to/.pgpass 7
#Example ./generic_db_backup.sh library.gwu.edu mysql archiviststoolkit /vol/backup someuser /path/to/.my.cnf 7

##########
#MySQL Setup:
#Update .my.cnf
#Set permissions 0600
##########

##########
#PostgreSQL Setup:
#Update .pgpass
#Set permissions 0600
##########

DNS=$1
DB_TYPE=$2
DB_NAME=$3
DESTINATION="$4/$DNS"
USERNAME=$5
PASSFILE=$6
if [ $DB_TYPE = psql ]
	then
	PGPASSFILE=$PASSFILE
	export PGPASSFILE
fi
TIME=$7
NOW=$(date +"%b-%d-%y-%H:%M:%S")
NAME=$DNS-SQL-$NOW
EMAIL=gwlib-root@groups.gwu.edu

#Ensure backup destination exists
if [ ! -d $DESTINATION ]
	then
	mkdir -p $DESTINATION
fi

#Execute appropriate database dump for each DB type
if [ $DB_TYPE = psql ]
	then
	pg_dump $DB_NAME -U $USERNAME -h localhost -Fc > $DESTINATION/$NAME.sql
	PGPASSFILE=""
	export PGPASSFILE
elif [ $DB_TYPE = mysql ] 
	then
	mysqldump --defaults-extra-file=$PASSFILE -h localhost --lock-all-tables $DB_NAME > $DESTINATION/$NAME.sql
else
	echo "Invalid database type"
fi

#Compress the selected folder
if [ -f $DESTINATION/$NAME.sql ]
	then
	tar -zcvf $DESTINATION/$NAME.tar $DESTINATION/$NAME.sql
else
	echo "Database dumb failed"
fi

#Cleanup sql files if tar files exist
if [ -f $DESTINATION/$NAME.tar ]
	then
	rm $DESTINATION/$NAME.sql
else
	echo "Compression failed"
fi

#Verify the compressed file was created
if [ -f $DESTINATION/$NAME.tar ]
	then
	#Cleanup existing backups if there is a current one
	find $DESTINATION/*SQL*.tar -type f -mtime +$TIME -exec rm -f {} \;
	#Send an email if successful and list all existing backups
	( echo "Backup of $DB_TYPE database executed successfully.  The following backups exist:"
		echo ""
		du -sh $DESTINATION/*SQL* ) | mail -s "['$DB_TYPE'dump] Report for $DNS" $EMAIL
else
	#If backup fails check for existing backups and alert accordingly
	if [ "$(ls -A $DESTINATION/*SQL*)" ]
		then
		( echo "Back of $DB_TYPE database failed. The following backups exist:"
			echo ""
			du -sh $DESTINATION/*SQL* ) | mail -s "[${DB_TYPE}dump] Report for $DNS" $EMAIL
	else
		echo "Backup of $DB_TYPE database failed.  No backups exist!" | mail -s "[${DB_TYPE}dump] Report for $DNS" $EMAIL
	fi
fi
