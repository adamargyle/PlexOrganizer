#!/bin/zsh

readonly source=$1
readonly destination=$2

local directory_count=0
local movie_count=0
local movie_skipped_count=0
local tvshow_count=0
local tvshow_skipped_count=0

echo "source is "$source
echo "destination is "$destination

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
            local title=$(grep -m 1 -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "<")
            local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
            local ext=$file:t:e
            local clean_title=${title//[:]/_}
            local full_title="${clean_title} (${year})"
            
            if [ ! -e "${destination}/Movies/${full_title}/${full_title}.${ext}" ]
            then
                if [ ! -d "${destination}/Movies/${full_title}" ]
                then
                    echo "creating directory ${destination}/Movies/${full_title}"
                    mkdir -p "${destination}/Movies/${full_title}"
                fi

                echo "copying file to ${destination}/Movies/${full_title}/${full_title}.${ext}"
                cp  "${file}" "${destination}/Movies/${full_title}/${full_title}.${ext}"
                ((movie_count++))
            else
                echo "${destination}/Movies/${full_title}/${full_title}.${ext} exists, skipping file"
                ((movie_skipped_count++))

            fi

        elif [ "$media_type" = '10' ]
        then
            local show=$(grep -m 1 -i 'show' <<<$metadata | cut -d '=' -f2)
            local season=$(grep -m 1 -i 'season_number' <<<$metadata | cut -d '=' -f2)
            local episode=$(grep -m 1 -i 'episode_sort' <<<$metadata | cut -d '=' -f2)
            local title=$(grep -m 1 -i 'title' <<<$metadata | cut -d '=' -f2 | grep -v -e "Chapter" | grep -v -e "<")
            local year=$(grep -m 1 -i 'date' <<<$metadata | grep -v -e "<" | cut -d '=' -f2 | read -eu0 -k4)
            local clean_show=${show//[:]/_}
            local full_title="${clean_show} - s${season}e${episode} - ${title}"
            local ext=$file:t:e

            if [ ! -e "${destination}/TV Shows/${clean_show}/Season ${season}/${full_title}.${ext}" ]
            then

                if [ ! -d "${destination}/TV Shows/${clean_show}" ]
                then
                    echo "creating directory ${destination}/TV Shows/${clean_show}"
                    mkdir -p "${destination}/TV Shows/${clean_show}"
                fi

                if [ ! -d "${destination}/TV Shows/${clean_show}/Season ${season}" ]
                then
                    echo "creating directory ${destination}/TV Shows/${show}/Season ${season}"
                    mkdir -p "${destination}/TV Shows/${clean_show}/Season ${season}"
                fi

                echo "copying file to ${destination}/TV Shows/${clean_show}/Season ${season}/${full_title}.${ext}"
                cp  "${file}" "${destination}/TV Shows/${clean_show}/Season ${season}/${full_title}.${ext}"
                ((tvshow_count++))
            else
                echo "${destination}/TV Shows/${clean_show}/Season ${season}/${full_title}.${ext} exists, skipping"
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