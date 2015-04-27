#!/bin/bash
# Crawls manga-joy and pulls entire manga chapters.
# I'm not sure how to describe it (yet), but there's a way to find the manga id.  If you read this code you might get a hint :)
# If you want to include a path to save the chapters to, please enclose it with quotes rather than escaping characters.

if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
	echo "usage: "$0" manga_id chapter_number [/path/to/chapters]"
	exit
fi
path=$3
if [ -z "$path" ]; then
	path="./"
fi
if [[ ${path: -1} != "/" ]]; then
	echo "error: path to download chapters to is invalid (does the path end with \"/\"?). Exiting"
	exit
fi
bse="http://manga-joy.com/wp-content/manga/"$1"/"
ch=$2
((ch-=1))
curl --silent $bse$ch"/" | grep p_.*\.jpg > /tmp/manga
((ch+=1))
mx=$(wc -l /tmp/manga | cut -f1 -d" ")
if [ $mx -eq 0 ]; then
	echo "error: chapter number "$2" for given manga does not exist. exiting"
	exit
fi
chg=$ch
len=${#chg}
while [ $len -lt 4 ]; do
	chg="0"$chg
	((len+=1))
done
chg="c_"$chg
mkdir "$path$chg"
pg=1
while [ $pg -le $mx ]; do
	len=${#pg}
	pgg=$pg
	while [ $len -lt 5 ]; do
		pgg="0"$pgg
		((len+=1))
	done
	pgg="p_"$pgg".jpg"
	echo "grabbing page "$pg" of "$mx" for chapter "$ch", saving to "$path$chg"/"$pgg"..."
	full=$path$chg"/"$pgg
	echo $bse$ch"/"$pgg
	curl --silent $bse$ch"/"$pgg > "$full"
	((pg+=1))
done
rm /tmp/manga
echo "all "$mx" pages saved in directory \""$path$chg"\"."
