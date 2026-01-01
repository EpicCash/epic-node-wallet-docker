#!/bin/bash
if [ -e ~/.epic/main/bs ]
then
	echo "chain_data exists - no bootstrap needed..."
else
	echo "Setting up bootstrap chain_data file..."
	wget -nv --show-progress --no-check-certificate https://bootstrap.epiccash.com/bootstrap.zip -P ~/.epic/main
	rm -R ~/.epic/main/chain_data
	unzip ~/.epic/main/bootstrap.zip -d ~/.epic/main
	rm ~/.epic/main/bootstrap.zip
	touch ~/.epic/main/bs
	echo "Done"
fi

/usr/bin/screen -dmS epicnode /home/epicsvcs/epic-node

tail -f /dev/null


