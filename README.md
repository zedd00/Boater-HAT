# Boater-HAT
Boater-HAT configures Home Automation Technologies using Docker. It protects you from the elements while it's guiding you down the river Docker. Once it helps you get to Port, you'll have all of the tools you need to aquire, manage, and share your media.

## Buzzword Description
Boater-HAT configures Docker, then sets up an nginx reverse proxy with automatic let's encrypt SSL certificates. Portainer is installed to give easy, clickable, control of Docker containers. Plex, Ubooquity, and Airsonic are installed to give you secure access to your media, anywhere. Ombi allows your Plex users to request media. Sonarr, Radarr, Lidarr, and Lazy Librarian manage those requests, and your media. NZBGet and Transmission save you from having to rip media yourself, while OpenVPN keeps you safe. Beets uses MusicBrains to give you extensive control of your MP3s. Filebot does the same for your movies. Hydra2 and Jackett minimize the number of times you have to confgure new downloaders. HTPC Manager puts access to everything on a single URL. Watchtower keeps it all updated.  

## Requirements:  
1 freshly installed copy of Ubuntu Server  
1 Samba share for media, or a second VM with Ubuntu Server  
A Domain with the following A records pointed at your IP:  
  1. port
  1. htpc
  1. ombi
  1. music
  1. read
  
The following TCP ports forwarded to your Docker Host:
  1. 80
  1. 443
  1. 32400

Upnp enabled on your router  
An Open VPN account with one of the providers listed at https://hub.docker.com/r/haugene/transmission-openvpn
A MusicBrainz API key from https://metabrainz.org/supporters/account-type
A Plex Account from https://plex.tv

## Installation instructions
If you don't already have a Samba share  
  1. Download samba-setup.sh to the VM you want to use for your media
  1. Set the variables in the script
  1. Run `bash samba-setup.sh`
    * You'll be prompted for your sudo password and to create a smb share password  
	
If you already have a share  
  1. Make sure your movies organized in the structure MovieFolder/MovieName(Year)/MovieName(Year).xxx  
    * movie-sort.sh will move movies from MovieFolder/MoveName(Year).xxx to MovieFolder/MovieName(Year)/MovieName(Year).xxx  
	* Place movie-sort.sh into the MovieFolder, run it with `bash movie-sort.sh'
	
In your Docker VM, download boater.sh. Run it with `bash boater.sh` and type y when asked if you want to install interactively. You can also set the variables at the begining of the script, and run it non-interactivly. 
Do what the prompts say until the VM reboots, then run `bash boater.sh` again. Follow the prompts until the script completes. 
It outputs cheat-sheet.txt when it completes. That file has URLs, needed API Keys, descriptions, and exposed ports for all of the services that were installed. Eventually, Boater-HAT will configure everything automatically, but currently it has to be done by hand.