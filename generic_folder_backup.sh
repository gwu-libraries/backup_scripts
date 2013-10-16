#!/bin/bash
#Usage: ./generic_folder_backup.sh <DNS name> <source folder> <destination> <retention time in days> <recipient email>
#Example ./generic_folder_backup.sh library.gwu.edu /etc/apache2/sites-available /vol/backup 7 noreply@gwu.edu
DNS=$1
SOURCE=$2
DESTINATION="$3/$DNS"
TIME=$4
NOW=$(date +"%b-%d-%y-%H:%M:%S")
NAME=$DNS-$(basename $SOURCE)-$NOW
EMAIL=$5

#Ensure backup destination exists
if [ ! -d $DESTINATION ]
	then
	mkdir -p $DESTINATION
fi

#Compress the selected folder
tar -zcvf $DESTINATION/$NAME.tar $SOURCE

#Verify the compressed file was created
if [ -f $DESTINATION/$NAME.tar ]
	then
	#Cleanup existing backups if there is a current one
	find $DESTINATION/*$(basename $SOURCE)*.tar -type f -mtime +$TIME -exec rm -f {} \;
	#Send an email if successful and list all existing backups
	( echo "Backup of $SOURCE executed successfully.  The following backups exist:"
		echo ""
		du -sh $DESTINATION/*$(basename $SOURCE)* ) | mail -s "[backup] Report for $DNS" $EMAIL
else
	#If backup fails check for existing backups and alert accordingly
	if [ "$(ls -A $DESTINATION/*$(basename $SOURCE)*)" ]
		then
		( echo "Back of $SOURCE failed. The following backups exist:"
			echo ""
			du -sh $DESTINATION/*$(basename $SOURCE)* ) | mail -s "[backup] Report for $DNS" $EMAIL
	else
		echo "Backup of $SOURCE failed.  No backups exist!" | mail -s "[backup] Report for $DNS" $EMAIL
	fi
fi
