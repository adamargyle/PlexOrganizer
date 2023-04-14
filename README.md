# PlexOrganizer
For years I had been organizing my Movies and TV Shows within iTunes and using the exellent [subler](https://subler.org) to ensure my metadata was correct and iTunes organized my files for me. Over the last several years I have shifted much of my content to consume via Plex because of features like shuffle and autoplaying the next episode of a TV Series. I'm working on this script as a way to import my media as iTunes previously did for my Plex library. This relies on the metadata being added and uses the `title` and `date` fields for Movies and in TV shows uses `show`, `season_number`, `episode_sort`, and `title` to try and create the best matches for plex's preferred naming conventions for [movies](https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/) and [tv shows](https://support.plex.tv/articles/naming-and-organizing-your-tv-show-files/).
 
## Usage:
`plexorganizer.sh` `source` `destination`

Run the script from a source folder of video files with metadata including at least title and release data and it will create folders with a movie name including the year and movie file within. It will work with TV shows nested in a folder for each sesaon under a main folder of `show title`. TV shows additionally need `show`, `season_number`, and `episode_sort` entries in their metadata. It currently will work from a single `${source}` folder for both Movie and TV Show media types and the output folders are `${destination}\Movies` and `${destination}\TV Shows`. At the end of the loop it will count how many subdirectories were scanned, and how many Movies/TV Shows were copied (or skipped if they exist).

## Dependencies: 
Requires `ffmpeg` to get metadata

## Notes:
This is still a work in progress. Plans for future iterations:
- Filtering names by removing unneeded attributes like "Director's Cut" or "Unrated Editon" and if needed moving them to the plex supported structure.
- Check for filenames that are too long, log error if it is too long (happens sometimes with metatdata formatting issues)
- Optionally Remove/Delete the source files
- Organize the folder you are in by simply moving the files into new folders with appropriate names.
- Cleanup at the end by removing empty folders in the destination.
- Log errors such as filenames that are too long (this happens with some titles where the metadata seems to not be formatted correctly).
- Add functions for some of the logic to allow for more options with less code
- Rewrite entirely in python.