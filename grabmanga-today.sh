#!/bin/bash
# Crawls manga-joy and pulls entire manga chapters.
# I'm not sure how to describe it (yet), but there's a way to find the manga id.  If you read this code you might get a hint :)
# If you want to include a path to save the chapters to, please enclose it with quotes rather than escaping characters.

trap ded INT
function ded()
{
	echo "grab cancelled, exiting..."
	rm /tmp/manga /tmp/manga2 /tmp/manga3 /tmp/manga4 2> /dev/null
	exit
}
if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
	echo "usage: "$0" manga_id chapter_number [/path/to/chapters]"
	exit
fi
ext=$4
if [ -z "$4" ]; then
	ext="png"
fi
echo "about to grab "$ext"s for manga id "$1", chapter "$2"..."
path=$3
if [ -z "$path" ]; then
	path="./"
fi
if [[ ${path: -1} != "/" ]]; then
	echo "error: path to download chapters to is invalid (does the path end with \"/\"?). Exiting"
	exit
fi
bse="http://funmanga.com/uploads/chapters/"$1"/"
ch=$2
((ch-=1))
curl --silent $bse$ch"/" | grep href.*/$ch/.*\.$ext > /tmp/manga
if [ -f "/tmp/manga2" ]; then
	sed 's/ //g' /tmp/manga | sed 's/<i.*\">//g' | sed 's/<.*//g' | sed 's/\..*//g' | sed '/^$/d' > /tmp/manga3
	comm -13 /tmp/manga2 /tmp/manga3 > /tmp/manga4
	mv /tmp/manga4 /tmp/manga2
	rm /tmp/manga3
else
	sed 's/ //g' /tmp/manga | sed 's/<i.*\">//g' | sed 's/<.*//g' | sed 's/\..*//g' | sed '/^$/d' > /tmp/manga2
fi
((ch+=1))
mx=$(wc -l /tmp/manga2 | cut -f1 -d" ")
if [ $mx -eq 0 ]; then
	if [ "$ext" = "jpg" ]; then
		echo "error: chapter number "$2" for given manga does not exist. exiting"
		rm /tmp/manga /tmp/manga2
		exit
	else
		echo "warning: no "$ext"s found.  trying jpgs..."
		$0 $1 $2 "$path" "jpg"
		exit
	fi
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
	curl --silent $bse$ch"/"$pg"."$ext > "$full"
	((ch+=1))
done </tmp/manga2
echo "all "$mx" "$ext" pages saved in directory \""$path$chg"\"."
if [ "$ext" != "jpg" ]; then
	$0 $1 $2 "$path" "jpg"
	rm /tmp/manga /tmp/manga2
fi
exit
