#!/bin/bash
# A script to move movies into individual folders
# Run this in your /Movies folder to move each file into a folder with the same name
# This speeds up Plex processing, and allows Radarr to monitor your movie collection. 
for file in *.*; do
folder="${file%.*}"
mkdir -p "$folder"
mv "$file" "$folder"
done
