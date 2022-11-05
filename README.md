# PlexOrganizer
For years I had been organizing my Movies and TV Shows within iTunes and using the exellent [subler](https://subler.org) to ensure my metadata worked perfecty and iTunes organized my files for me. Over the last several years I have shifted much of my content to consume via Plex because of features like shuffle and autoplaying the next episode of a TV Series. I'm working on this script as a way to import my media as iTunes previously did for my Plex library. This relies on the metadata being added and uses the `title` and `date` fields for Movies and in TV shows uses `show`, `season_number`, `episode_sort`, and `title` to try and create the best matches for plex's preferred naming conventions for [movies](https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/) and [tv shows](https://support.plex.tv/articles/naming-and-organizing-your-tv-show-files/).
 
## Usage:
`plexorganizer.sh` `source` `destination`

Run the script from a source folder of encoded videos with metadata including at least title and release data and it will create folders with a movie name including the year and movie file within. It will work with TV shows nested in a folder for each sesaon under a main folder of `show title`. TV shows additionally need `show`, `season_number`, and `episode_sort` entries in their metadata.

## Dependencies: 
Requires `ffmpeg` to get metadata

## Notes:
This is still a work in progress. Plans for futute iteration:
- Filtering names by removing unneeded attributes like "Director's Cut" or "Unrated Editon" and if needed moving them to the plex supported structure.
- Optionally Remove/Delete the source files
- Organize the folder you are in by simply moving the files into new folders with appropriate names.
- Cleanup at the end by removing empty folders in the destination.
- Optionally log the number of files successfully copied/moved.
- Log errors such as filenames that are too long (this happens with some titles where the metadata seems to not be formatted correctly).
- Rewrite entirely in python.