#!/bin/bash
#
# YouTube2RSS. (c) José Puga. 2023. Under MIT License.
# Version 1.0.0
#
if [[ "$DISPLAY" == "" ]]; then
	echo "This program runs in graphic mode."
	exit 1
fi
which kdialog &> /dev/null
if [[ $? > 0 ]]; then
	echo "kdialog must be installed."
	exit 1
fi

app_name="YouTube2RSS"
while :; do	# Loop until user cancel a dialog or error
	url=$(kdialog --title "$app_name" --inputbox "YouTube channel, video or playlist URL: $(printf "%0.s " {1..60})") # Spaces = Dialog width hack
	if [[ $? > 0 ]]; then # Cancel pressed
		exit 1
	fi

	# Actually playlist do not need utlarge.com service, because dont use youtube ID,
	# but this way, we can verify if the url is correct.
	user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/114.0"
	content=$(curl -X POST https://ytlarge.com/youtube/channel-id-finder/ \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-H "Cache-Control: no-cache, no-store" \
		-A "$user_agent" -d "v=$url" --silent)

	if [[ $? > 0 ]]; then
		kdialog --error "Unable to connect to ytlarge.com service."
		exit 1
	fi

	if ! grep -q "https://www.youtube.com/channel/" <<< "$content"; then
		kdialog --error "Cannot find the Channel ID."
		exit 1
	fi

	url_rss="https://www.youtube.com/feeds/videos.xml"
	if grep -q "&list=" <<< $url; then # playlist
		field1="&list="
		field2="&"
		id=${url#*$field1}
		id=${id%%$field2*}
		url_rss="$url_rss?playlist_id=$id"
	else # channel
		field1="https://www.youtube.com/channel/"
		field2="'"
		id=${content#*$field1}  # Remove up to (and including) $field1.
		id=${id%%$field2*}  # Remove from the first $field2 to the end.
		url_rss="$url_rss?channel_id=$id"
	fi
	kdialog --title "$app_name" --msgbox "$url_rss" "Right-click on URL\n<Select All>\n<Copy>"
	if [[ $? > 0 ]]; then
		exit 1
	fi
done


