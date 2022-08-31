#!/bin/zsh

readonly source=$1
readonly destination=$2
#readonly testing=$3

echo "source is "$source
echo "destination is "$destination

# somehow everything seemed to turn on testing mode... 
#if [ $testing =  ]
# echo "testing mode is on"
# then
#     for file in $source/*
#     do
#         local title=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - | grep -i 'title' | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
#         local year=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - | grep -i 'date' | grep -v -e "<" | cut -d '=' -f2 | cut -d '-' -f1 )
#         local full_title="${title} (${year})"
#         echo "${full_title}"
#     done
#     echo "testing mode complete"
#     exit 0
# fi

for file in $source/*
do
    #further logice needed: check if item is a movie or tv show, process tv show with separate workflow
    #check if destination folder already exists
    #remove unrated edition/director's cut/ etc or use the new edition tags for plex instead
    local title=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - | grep -i 'title' | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
    local year=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - | grep -i 'date' | grep -v -e "<" | cut -d '=' -f2 | cut -d '-' -f1 )
    local ext=$file:t:e
    local full_title="${title} (${year})"

    echo "creating directory ${destination}/${full_title}"
    mkdir -p "${destination}/${full_title}"

    echo "copying file to ${destination}/${full_title}/${full_title}.${ext}"
    cp  "${file}" "${destination}/${full_title}/${full_title}.${ext}"
done
echo "file copy complete"