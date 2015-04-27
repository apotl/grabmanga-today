#!/bin/bash
# Crawls manga-joy and pulls entire manga chapters.
# I'm not sure how to describe it (yet), but there's a way to find the manga id.  If you read this code you might get a hint :)
# If you want to include a path to save the chapters to, please enclose it with quotes rather than escaping characters.

ext="png"
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
curl --silent $bse$ch"/" | grep 0.*\.$ext > /tmp/manga
sed 's/ //g' /tmp/manga | sed 's/<i.*\">//g' | sed 's/<.*//g' > /tmp/manga2
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
while read pg; do
	pgn=$(echo $pg | sed 's/\..*//g' | sed 's/[^[:digit:]]//g')
	len=${#pgn}
	pgg=$pgn
	while [ $len -lt 5 ]; do
		pgg="0"$pgg
		((len+=1))
	done
	pgg="p_"$pgg"."$ext
	echo "grabbing page "$pgn" of "$mx" total for chapter "$ch", saving to "$path$chg"/"$pgg"..."
	full=$path$chg"/"$pgg
	((ch-=1))
	curl --silent $bse$ch"/"$pgg > "$full"
	((ch+=1))
done </tmp/manga2
rm /tmp/manga /tmp/manga2
echo "all "$mx" pages saved in directory \""$path$chg"\"."
