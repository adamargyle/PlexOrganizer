#!/bin/zsh

# author awickert, last updated 01/03/2025
# organize tv shows and movies for plex libraries using metadata in the file via ffmpeg

readonly source=$1
readonly destination=$2

local directory_count=0
local movie_count=0
local movie_skipped_count=0
local tvshow_count=0
local tvshow_skipped_count=0
local copy_action=cp

# check if source/destination are mounted, error and exit if they are not
if [ -e "${source}" ] 
then
    echo "Source is "$source
else 
    echo "Error: Source is not mounted."
    exit 1
fi

if [ -e "${destination}" ] 
then
    echo "Destination is "$destination
else 
    echo "Error: Destination is not mounted."
    exit 1
fi

# check if the source and destination are the same, if so we will rename the files and folders instead of copying them
if [[ "${source}" == "${destination}" ]]
then
    echo "Source and desintation are set to the same folder."
    echo "Renaming files and folders in place."
    copy_action=mv

fi

# check through each file in the soure directories metatdata with ffmpeg to pull out the movie title/show and year
for file in $source/**/*
do
    if [ -d "${file}" ]
    then
        echo "${file} is a directory"
        ((directory_count++))
    else

        local metadata=$(ffmpeg -y -loglevel error -i ${file} -f ffmetadata - )
        local media_type=$(grep -i 'media_type' <<<$metadata | cut -d '=' -f2)
        if [ "$media_type" = '9' ]
        then
            local title=$(grep -m 1 -i 'title' <<<$metadata | grep -v -e "<" | cut -d '=' -f2)
            local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
            local ext=$file:t:e
            local clean_title=${title//[:]/_}
            local full_title="${clean_title} (${year})"
            
            if [ ! -e "${destination}/Movies/${full_title}/${full_title}.${ext}" ]
            then
                if [ -d "${destination}/Movies/${clean_title}" ] 
                then
                    echo "copying file to ${destination}Movies/${full_title}/${full_title}.${ext}"
                    mv  "${file}" "${destination}/Movies/${clean_title}/${full_title}.${ext}"
                    echo "renaming directory to ${destination}Movies/${full_title}"
                    mv "${destination}/Movies/${clean_title}" "${destination}/Movies/${full_title}"

                elif [ ! -d "${destination}Movies/${full_title}" ]
                then
                    echo "creating directory ${destination}Movies/${full_title}"
                    mkdir -p "${destination}/Movies/${full_title}"
                    echo "copying file to ${destination}Movies/${full_title}/${full_title}.${ext}"
                    cp  "${file}" "${destination}/Movies/${full_title}/${full_title}.${ext}"
                   
                fi

                ((movie_count++))
            else
                echo "${destination}Movies/${full_title}/${full_title}.${ext} exists, skipping file"
                ((movie_skipped_count++))

            fi

        elif [ "$media_type" = '10' ]
        then
            local show=$(grep -m 1 -i 'show=' <<<$metadata | cut -d '=' -f2)
            local season=$(grep -m 1 -i 'season_number' <<<$metadata | cut -d '=' -f2)
            local episode=$(grep -m 1 -i 'episode_sort' <<<$metadata | cut -d '=' -f2)
            local title=$(grep -m 1 -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
            local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
            local clean_show=${show//[:]/_}
            local clean_title=${title//[\/]/_}
            local full_title="${clean_show} - s${season}e${episode} - ${clean_title}"
            local ext=$file:t:e
            local season_full="Season ${season}"

            if [[ $season -eq "0" ]]
            then
                local season_full="Specials"      
            fi

            if [ ! -e "${destination}/TV Shows/${clean_show}/${season_full}/${full_title}.${ext}" ]
            then

                if [ ! -d "${destination}/TV Shows/${clean_show}" ]
                then
                    echo "creating directory ${destination}TV Shows/${clean_show}"
                    mkdir -p "${destination}/TV Shows/${clean_show}"
                fi

                if [ ! -d "${destination}/TV Shows/${clean_show}/${season_full}" ]
                then
                    echo "creating directory ${destination}TV Shows/${show}/${season_full}"
                    mkdir -p "${destination}/TV Shows/${clean_show}/${season_full}"
                fi

                echo "copying file to ${destination}TV Shows/${clean_show}/${season_full}/${full_title}.${ext}"
                cp  "${file}" "${destination}/TV Shows/${clean_show}/${season_full}/${full_title}.${ext}"
                ((tvshow_count++))
            else
                echo "${destination}TV Shows/${clean_show}/${season_full}/${full_title}.${ext} exists, skipping"
                ((tvshow_skipped_count++))
            fi

        fi       
    fi

done

echo "File copy complete"
echo "${directory_count} Subdirectories scanned"
echo "${movie_count} Movies copied"
echo "${movie_skipped_count} Movies skipped (files already exist)"
echo "${tvshow_count} TV Show Episodes copied"
echo "${tvshow_skipped_count} TV Episodes skipped (files already exist)"