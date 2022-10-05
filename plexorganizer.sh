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
    # further logic needed: check if item is a movie or tv show, process tv show with separate workflow
    # take all metadata in one variable, check media type (9=movie, 10=tv), then pull out release year and title on movies, and tv show, episode title, season and episode number on tv shows. check first if a folder exists
    #remove unrated edition/director's cut/ etc or use the new edition tags for plex instead
    #check for file characters that might not be good (punctuation mostly)

    local metadata=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - )
    local media_type=$(grep -i 'media_type' <<<$metadata | cut -d '=' -f2)
    
    if [ "$media_type" = '9' ]
    then
        local title=$(grep -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
        local year=$(grep -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
        local ext=$file:t:e
        local full_title="${title} (${year})"

        echo "creating directory ${destination}/${full_title}"
        mkdir -p "${destination}/${full_title}"

        echo "copying file to ${destination}/${full_title}/${full_title}.${ext}"
        cp  "${file}" "${destination}/${full_title}/${full_title}.${ext}"

    elif [ "$media_type" = '10' ]
    then
        local show=$(grep -i 'show' <<<$metadata | cut -d '=' -f2)
        local season=$(grep -i 'season_number' <<<$metadata | cut -d '=' -f2)
        local episode=$(grep -i 'track' <<<$metadata | cut -d '=' -f2)
        local title=$(grep -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
        local year=$(grep -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
        local ext=$file:t:e
        if [ -e "${destination}/${show}" ]
        then
            mkdir -p "${destination}/${show}/${season}"
        else

        fi

    fi

done
echo "file copy complete"