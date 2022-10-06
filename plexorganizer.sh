#!/bin/zsh

readonly source=$1
readonly destination=$2

echo "source is "$source
echo "destination is "$destination

for file in $source/*
do

    # remove unrated edition/director's cut/ etc or use the new edition tags for plex instead
    # count files copied and echo at the end the number of files copied successfully
    # need loops to be able to go through folders inside the main folder
    # option to rename files in the same folder instead of copying them
    # check for file characters that are not valid (punctuation mostly) and total character count
    # log errors

    local metadata=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - )
    local media_type=$(grep -i 'media_type' <<<$metadata | cut -d '=' -f2)
    
    if [ "$media_type" = '9' ]
    then
        local title=$(grep -m 1 -i 'title' <<<$metadata | cut -d '=' -f2)
        local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
        local ext=$file:t:e
        local full_title="${title} (${year})"

        if [ ! -e "${destination}/${full_title}/${full_title}.${ext}" ]
        then
            if [ ! -d "${destination}/${full_title}" ]
            then
                echo "creating directory ${destination}/${full_title}"
                mkdir -p "${destination}/${full_title}"
            fi

            echo "copying file to ${destination}/${full_title}/${full_title}.${ext}"
            cp  "${file}" "${destination}/${full_title}/${full_title}.${ext}"

        fi

    elif [ "$media_type" = '10' ]
    then
        local show=$(grep -m 1 -i 'show' <<<$metadata | cut -d '=' -f2)
        local season=$(grep -m 1 -i 'season_number' <<<$metadata | cut -d '=' -f2)
        local episode=$(grep -m 1 -i 'episode_sort' <<<$metadata | cut -d '=' -f2)
        local title=$(grep -m 1 -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
        local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
        local full_title="${show} - s${season}e${episode} - ${title}"
        local ext=$file:t:e

        if [ ! -e "${destination}/${show}/Season ${season}/${full_title}.${ext}" ]
        then

            if [ ! -d "${destination}/${show}" ]
            then
                echo "creating directory ${destination}/${show}"
                mkdir -p "${destination}/${show}"
            fi

            if [ ! -d "${destination}/${show}/Season ${season}" ]
            then
                echo "creating directory ${destination}/${show}/Season ${season}"
                mkdir -p "${destination}/${show}/Season ${season}"
            fi

            echo "copying file to ${destination}/${show}/Season ${season}/${full_title}.${ext}"
            cp  "${file}" "${destination}/${show}/Season ${season}/${full_title}.${ext}"
        fi

    fi

done
echo "file copy complete"