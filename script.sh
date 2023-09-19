#!/bin/bash

set -xe

timeout=10

function main {
	set_up
	query=$(build_query "$@")
	curl_img $(get_href "$query")
	if [ $(get_desktop_img) != $fpath ]; then
		set_desktop_img
	fi
}

function set_up {
	usr="$(whoami)"
	if [ $usr = "root" ]; then
		echo "don't run as root"
		return 1
	fi

	dir="/home/"$usr"/Pictures/Wallpapers/randwp"
	if [ ! -d $dir ]; then
		mkdir $dir
	fi

	fpath="${dir}/image"
}

function build_query {
	query=""
	if [[ ! -z "$@" ]]; then
		query+="?"; i=0
		for e in "$@"; do
			# Replace any spaces with hypens.
			# Not totally sure, but I think that's how searches with two or more words is handled?
			# Otherwise, sub for %20 or +.
			query+="${e// /-}"
			let "i+=1"
			if [ $i -lt ${#@} ]; then
				query+=","	
			fi
		done
	fi
	echo "${query}"
}

function get_resolution { xrandr --current | grep "*" | uniq | awk '{print $1}'; }

function get_href {
	# I assume because accessing unsplash this way is deprecated, the request gets redirected.
	# The response is a snippet of html, but it will include a href to an image.
	tmp=$(curl -s --connect-timeout $timeout "https://source.unsplash.com/random/"$(get_resolution)"/"$1)
	echo $tmp | grep -oP 'href="\K[^"]+'
}

function curl_img {
	$(curl -s --connect-timeout $timeout $1 > $fpath)
}

function get_desktop_img {
	path=$(gsettings get org.gnome.desktop.background picture-uri)
	# strip surrounding single quotes.
	echo "$path" | tr -d ''\'
}

function set_desktop_img {
	gsettings set org.gnome.desktop.background picture-uri $fpath
}

main "$@"

# Create link to bin/
# ln -s randwp/script.sh /home/usr/bin/randwp
# Create alias
# echo alias randwp=/home/usr/bin/randwp >> ~/.bash_aliases
