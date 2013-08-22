#!/bin/bash
#Usage: ./backup.sh <DNS name> <source folder> <destination>
#Example ./backup.sh library.gwu.edu /etc/apache2/sites-available /vol/backup
DNS=$1
SOURCE=$2
DESTINATION="$3/$DNS"
NOW=$(date +"%b-%d-%y")
NAME=$DNS-$NOW
EMAIL=gwlib-root@groups.gwu.edu

#Ensure backup destination exists
if [ ! -d $DESTINATION ]
	then
	mkdir -p $DESTINATION
fi

#Compress the selected folder
tar -zcvf $DESTINATION/$NAME.tar $SOURCE

#Verify the compressed file was created
if [ -f $DESTINATION/$NAME.tar ]
	#Send an email if successful and list all existing backups
	then
	( echo "Backup of $SOURCE executed successfully.  The following backups exist:"
		echo ""
		du -sh $DESTINATION/* ) | mail -s "[backup] Report for $DNS" $EMAIL
else
	#If backup fails check for existing backups and alert accordingly
	if [ "$(ls -A $DESTINATION)" ]
		then
		( echo "Back of $SOURCE failed. The following backups exist:"
			echo ""
			du -sh $DESTINATION/* ) | mail -s "[backup] Report for $DNS" $EMAIL
	else
		echo "Backup of $SOURCE failed.  No backups exist!" mail -s "[backup] Report for $DNS" $EMAIL
	fi
fi