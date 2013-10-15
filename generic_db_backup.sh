#!/bin/bash
#Usage: ./db_backup.sh <DNS name> <DB type> <DB name> <destination>
#Example ./backup.sh library.gwu.edu psql archiviststoolkit /vol/backup /path/to/.mycnf (MySQL Only)
DNS=$1
DB_TYPE=$2
DB_NAME=$3
DESTINATION="$4/$DNS"
#For PSQL backups you must create a .pgpass file for password authentication from the cron job
PSQLCREDENTIALS=psqlbackupuser
#For MYSQL backup you must specify the location of a custom .mycnf.ini file for authentication from the cron job
MYSQLCREDENTIALS=$5
NOW=$(date +"%b-%d-%y")
NAME=$DNS-$NOW
EMAIL=gwlib-root@groups.gwu.edu

#Ensure backup destination exists
if [ ! -d $DESTINATION ]
	then
	mkdir -p $DESTINATION
fi

#Execute appropriate database dump for each DB type
if [ $DB_TYPE = psql ]
	then
	pg_dump $DB_NAME -U $USERNAME -h localhost -F c > $DESTINATION/$NAME.sql
elif [ $DB_TYPE = mysql ] 
	then
	mysqldump --defaults-extra-file=$MYSQLCREDENTIALS -h localhost --lock-all-tables $DB_NAME > $DESTINATION/$NAME.sql
else
	echo "Invalid database type"
fi

#Compress the selected folder
if [ -f $DESTINATION/$NAME.sql ]
	then
	tar -zcvf $DESTINATION/$NAME.tar DESTINATION/$NAME.sql
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
	#Send an email if successful and list all existing backups
	then
	( echo "Backup of $DB_TYPE database executed successfully.  The following backups exist:"
		echo ""
		du -sh $DESTINATION/* ) | mail -s "['$DB_TYPE'dump] Report for $DNS" $EMAIL
else
	#If backup fails check for existing backups and alert accordingly
	if [ "$(ls -A $DESTINATION)" ]
		then
		( echo "Back of $DB_TYPE database failed. The following backups exist:"
			echo ""
			du -sh $DESTINATION/* ) | mail -s "['$DB_TYPE'dump] Report for $DNS" $EMAIL
	else
		echo "Backup of $DB_TYPE database failed.  No backups exist!" mail -s "['$DB_TYPE'dump] Report for $DNS" $EMAIL
	fi
fi
