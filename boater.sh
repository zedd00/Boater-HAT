#!/bin/bash
# This script mounts your samba share, installs docker, creates the media management environment, and outputs a file to help with configuring all of the services
# Make sure ports 80, 443, and 32400 are forwarded to your docker IP in NAT on your router, also enable Upnp before continuing
# Create the following list of subdomains, and make sure that they are pointed at your IP:
######################## These will be available outside your network so ensure they are password protected####################
### port
### htpc
### ombi
### music
### read
#!!!! To install without interaction, set these variables !!!!!!!!#
# Location where you want your share mounted. example: "/media/share"
shareddrive="/media/share"
# Share location. example: "//192.168.1.30/sharename"
sambashare="//192.168.1.30/Boater_share/test"
# Domain that is pointing at your home IP. example: "domain.com"
externaldomain="HAT-Labs.com"
# Email address for registering SSL Certificates. example: "test@fake.com
emailaddy="bo@ter.com"
# Time Zone as defined at https://en.wikipedia.org/wiki/List_of_tz_database_time_zones example: "America/Los_Angeles"
timezone="America/Los_Angeles"
# Name for your plex server
plexname="Boater"
# User for accessing the shared drive
meduser="boater"
# Password for accessing the shared drive
medpass="barge"
# IP of your docker host
dockerip=192.168.1.197
# OpenVPN Provider https://hub.docker.com/r/haugene/transmission-openvpn
vpnprovider="NORDVPN"
# VPN username
vpnuser="user@testertesterson.com"
# VPN password
vpnpass="password"
# Musicbrainz api code Get from https://metabrainz.org/supporters/account-type
brainzcode="register"
###### End of variables, there shouldn't be a need to edit anything else #############
if [ -z "$lemail" ]
then
	echo 'This script will install your Media Center.'
		echo 'Do you want to install interactively?'
		read -p '(y/n)?' interactive
		case "$interactive" in 
		  y|Y ) echo 'OK, interactive install starting.'
				echo 'Please confirm your environment is configured correctly.'
				echo 'Are ports 80, 443, and 32400 forwarded to this machine?'
				read -p '(y/n)?' choice
				case "$choice" in 
				  y|Y ) echo 'Great! Are portainer.yourdomain.com, htpc.yourdomain.com, ombi.yourdomain.com, music.yourdomain.com and read.yourdomain.com pointed to this external IP?';;
				  n|N ) echo 'Please check the setup guide located at placeholder.com then rerun this script.';
					exit 1;;
				  * ) echo 'Please enter y or n';;
				esac
				read -p '(y/n)?' choice
				case "$choice" in 
				  y|Y ) echo 'Fantastic, Do you have a samba share configured?';;
				  n|N ) echo 'Please check the setup guide located at placeholder.com then rerun this script.';
					exit 1;;
				  * ) echo 'Please enter y or n';;
				esac
				read -p '(y/n)?' choice
				case "$choice" in 
				  y|Y ) echo 'Wonderful, now we need some information on your setup';;
				  n|N ) echo 'Please check the setup guide located at placeholder.com then rerun this script.';
					exit 1;;
				  * ) echo 'Please enter y or n';;
				esac

				##################### Collect variables ########################
				echo "Where do you want your share drive mounted?"
				read -p  'For example: /media/share : ' shareddrive
				echo "Where is your share located?"
				read -p  'For example: //192.168.1.30/sharename : ' sambashare
				echo "What is the domain that is pointing at your external IP"
				read -p  'For example: domain.com : ' externaldomain
				echo "What email address do you want your SSL Certificates registered at?"
				read -p  'For example: test@fake.com : ' emailaddy
				echo "What does https://en.wikipedia.org/wiki/List_of_tz_database_time_zones say your timezone is?"
				read -p  'For example: America/Los_Angeles : ' timezone
				echo "What do you want your plex server to be named?"
				read -p  'For example: Plexinator : ' plexname
				echo "What is the IP of this machine?"
				read -p  'For example: 192.168.1.31 : ' dockerip
				echo "Please register and copy an api key from musicbrainz from https://metabrainz.org/supporters/account-type"
				read -p 'What is your Musicbrainz api key? : ' brainzcode
				echo "That's all of the environment information we need. On to Account information."

				##################### Collect Accounts ########################

				echo "What user has access to the shared drive?"
				read -p  'Username: ' meduser
				echo "What is the password for that user?"
				read -s  medpass
				echo "Are you ready to continue?"
				read -p "(y/n)?" choice
				case "$choice" in 
				  y|Y ) echo 'Starting install';;
				  n|N ) echo 'No Changes have been made to your system';
					exit 1;;
				  * ) echo 'Please enter y or n';;
				esac
				###### End of Accounts#############
				;;
		   n|N ) echo 'Skipping prompts.';;
		   * ) echo 'Please enter y or n';;
		esac
	# Create credentials file
	sudo bash -c ' echo "username='$meduser'" > /root/.smbcredentials'
	sudo bash -c ' echo "password='$medpass'" >> /root/.smbcredentials'
	sudo chmod 700 /root/.smbcredentials
	# Install cifs, add the share so it's available across reboots, mount it now.
	sudo apt update
	sudo apt upgrade -y
	sudo apt install cifs-utils -y
	sudo mkdir $shareddrive
	sudo cp /etc/fstab /etc/fstab_old
	sudo bash -c ' echo "'$sambashare'        '$shareddrive'    cifs   credentials=/root/.smbcredentials,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab'
	sudo bash -c ' echo "" >> /etc/fstab'
	sudo mount -a
	# Install needed programs, then docker
	sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update
	sudo apt-get install docker-ce -y	
	# Get username, add to docker group, get docker groupid
	pnid="$(id -nu)"
	sudo usermod -aG docker $pnid
	puid="$(id -u)"
	pgid="$(getent group docker | cut -d: -f3)"
	sudo chown -R $pnid:docker /var/lib/docker/volumes
	# Create the directories on the shared drive
	mkdir -p $shareddrive/test/media/Movies
	mkdir -p $shareddrive/test/media/TV
	mkdir -p $shareddrive/test/Downloads
	mkdir -p $shareddrive/test/Music
	mkdir -p $shareddrive/test/Library/books
	mkdir -p $shareddrive/test/Library/Comics
	# Add the variabls to /etc/environment so you can easily add containers later
	sudo bash -c ' echo "lemail=\"'$emailaddy'\"" >> /etc/environment' 
	sudo bash -c ' echo "dsock=\"/var/run/docker.sock:/var/run/docker.sock\"" >> /etc/environment' 
	sudo bash -c ' echo "dtime=\"/etc/localtime:/etc/localtime:ro\"" >> /etc/environment'
	sudo bash -c ' echo "TZ=\"'$timezone'\"" >> /etc/environment'  
	sudo bash -c ' echo "mediashare=\"'$shareddrive'/Media/\"" >> /etc/environment'  
	sudo bash -c ' echo "tvshare=\"'$shareddrive'/Media/TV\"" >> /etc/environment'  
	sudo bash -c ' echo "downloadshare=\"'$shareddrive'/Downloads\"" >> /etc/environment'  
	sudo bash -c ' echo "musicshare=\"'$shareddrive'/Music\"" >> /etc/environment'  
	sudo bash -c ' echo "bookshare=\"'$shareddrive'/Library/books\"" >> /etc/environment'  
	sudo bash -c ' echo "comicshare=\"'$shareddrive'/Library/Comics\"" >> /etc/environment'
	sudo bash -c ' echo "fileshare=\"'$shareddrive'\"" >> /etc/environment'  
	sudo bash -c ' echo "extdomain=\"'$externaldomain'\"" >> /etc/environment'   
	sudo bash -c ' echo "hostip=\"'$dockerip'\"" >> /etc/environment'   
	sudo bash -c ' echo "puid=\"'$puid'\"" >> /etc/environment'   
	sudo bash -c ' echo "pgid=\"'$pgid'\"" >> /etc/environment' 
	sudo bash -c ' echo "plexname=\"'$plexname'\"" >> /etc/environment'   
	sudo bash -c ' echo "bcode=\"'$brainzcode'\"" >> /etc/environment'   
	source /etc/environment
	echo "Are you ready to reboot?"
	read -p "(y/n)?" choice
	case "$choice" in 
	  y|Y ) echo 'Rebooting';;
	  n|N ) echo 'K';
		exit 1;;
	  * ) echo 'Please enter y or n';;
	esac
	sudo reboot
else
	echo "Are you ready to continue with docker setup?"
	read -p "(y/n)?" choice
	case "$choice" in 
	  y|Y ) echo "Starting install";;
	  n|N ) echo "I will try again the next time this machine is rebooted";
		exit 1;;
	  * ) echo 'Please enter y or n';;
	esac
	echo 'Are you installing interactively?'
		read -p '(y/n)?' interactive
		case "$interactive" in 
		  y|Y ) echo "OK, interactive install starting.";
				echo "A few more settings are needed to continue.";
				
			##################### Collect variables ########################
				echo "Who is your vpn provider"
				read -p  'Check https://hub.docker.com/r/haugene/transmission-openvpn for a list of supported providers : ' vpnprovider;
				echo "What is your username for the VPN?";
				read -p  'Username : ' vpnuser;
				echo "What is the password for your VPN?";
				read -s vpnpass;
				echo "Please go to https://www.plex.tv/claim and get your token";
				read -p  "Claim Token : " claim_token;
				echo "Thanks, install continuing.";;
		n|N ) echo 'Please go to https://www.plex.tv/claim and get your token';
			  read -p  'Claim Token : ' claim_token;;
		   * ) echo 'Please enter y or n';;
		esac
	pnid="$(id -nu)"
	sudo chown -R $pnid:docker /var/lib/docker/volumes	
# Plex allows your friends to share your movies, music, and TV
docker run --name plex -p 32400:32400 -e TZ=$TZ --network=host -h $plexname -v plex:/config -v plex-temp:/transcode -v $mediashare:/data -v $musicshare:/muxic -e PLEX_CLAIM=$claimtoken -d --restart always --memory="24g" plexinc/pms-docker:latest	

# Install nginx reverse proxy to redirect traffic to the correct docker containers
docker run --name nginx-proxy -p 80:80 -p 443:443 -v nginx-config:/etc/nginx/conf.d -v ~/certs:/etc/nginx/certs -v nginx-vhost:/etc/nginx/vhost.d -v nginx-html:/usr/share/nginx/html -v nginx-dhparam:/etc/nginx/dhparam -v /var/run/docker.sock:/tmp/docker.sock:ro -e ENABLE_IPV6=false --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true -d --restart always jwilder/nginx-proxy
	
# Install let's encrypt to secure traffic
docker run --name letsencrypt-nginx-proxy-companion -v ~/certs:/etc/nginx/certs:rw -v /var/run/docker.sock:/var/run/docker.sock:ro -v nginx-vhost:/etc/nginx/vhost.d -v nginx-html:/usr/share/nginx/html -v nginx-dhparam:/etc/nginx/dhparam -d --restart always jrcs/letsencrypt-nginx-proxy-companion 

# Install watchtower to update containers
docker run --name watchtower -v $dsock -d --restart always v2tec/watchtower	--cleanup -i 86400

# Portainer is a web interface for docker, so you can restart containers without the command line
docker run --name portainer -p 8001:9000 -v $dsock -v portainer:/data -e VIRTUAL_HOST=portainer.$extdomain -e VIRTUAL_PORT=8001 -e LETSENCRYPT_HOST=portainer.$extdomain -e LETSENCRYPT_EMAIL=$lemail --restart always -d portainer/portainer:latest -H unix:///var/run/docker.sock
# Sonarr finds TV shows
docker run --name sonarr -p 8002:8989 -e TZ=$TZ -v sonarr:/config -v $tvshare:/tv -v $downloadshare/TV:/downloads -e VIRTUAL_PORT=8002 -e PGID=$pgid -e PUID=$puid --restart always -d --memory="8g" linuxserver/sonarr:latest
# Radarr finds movies
docker run --name radarr -p 8003:7878 -e TZ=$TZ -v radarr:/config -v $downloadshare/Movies:/downloads -v $mediashare/movies:/movies -e VIRTUAL_PORT=8003 -e PGID=$pgid -e PUID=$puid --restart always -d --memory="8g" linuxserver/radarr:latest
# Lidarr finds music
docker run --name lidarr -p 8004:8686 -e TZ=$TZ -v lidarr:/config -v $downloadshare/Music:/downloads -v $musicshare:/music -e VIRTUAL_PORT=8004 -d -e PGID=$pgid -e PUID=$puid --restart always --memory="8g" linuxserver/lidarr:latest
# Lazy Librarian finds ebooks
docker run --name lazylibrarian -p 8005:5299 -e TZ=$TZ -v lazylibrarian:/config -v $downloadshare/Books:/downloads -v $bookshare/unsorted:/books -e VIRTUAL_PORT=8005 -e PGID=$pgid -e PUID=$puid -d --restart always --memory="8g" linuxserver/lazylibrarian:latest
# Hydra2 manages your indexers
docker run --name=hydra2 -p 8006:5076 -e TZ=$TZ -v hydra2:/config -v $downloadshare:/downloads -e VIRTUAL_HOST=hydra.$extdomain -e VIRTUAL_PORT=8006  -e PGID=$pgid -e PUID=$puid -d --restart always --memory="8g" linuxserver/hydra2:135
# Jackett manages your torrent indexers
docker run --name=jackett -p 8007:9117 -e TZ=$tz -v jackett:/config  -v $downloadshare:/downloads -e VIRTUAL_PORT=8007 -e PGID=$pgid -e PUID=$puid -d --restart always --memory="4g" linuxserver/jackett
# NZBget manages downloads
docker run --name=nzbget -p 8008:6789 -e TZ=$TZ -v nzbget:/config -v $downloadshare:/downloads -v $bookshare/unsorted:/downloads/Books -e VIRTUAL_PORT=8008 -e PGID=$pgid -e PUID=$puid -d --restart always --memory="16g" linuxserver/nzbget:latest	
# Ombi allows your Plex users to request new movies, music, and TV
docker run --name=ombi -p 8009:3579 -e TZ=$TZ -v ombi:/config -e VIRTUAL_HOST=ombi.$extdomain -e VIRTUAL_PORT=8009 -e LETSENCRYPT_HOST=ombi.$extdomain -e LETSENCRYPT_EMAIL=$lemail -d --restart always --memory="8g" linuxserver/ombi
# HTPC Manager will allow you to view the installed services in a single page
docker run --name=htpc -p 8010:8085 -e TZ=$TZ -v htpc:/config -e VIRTUAL_HOST=htpc.$extdomain -e VIRTUAL_PORT=8010 -e LETSENCRYPT_HOST=htpc.$extdomain -e LETSENCRYPT_EMAIL=$lemail -e PGID=$pgid -e PUID=$puid -d --restart always --memory="8g" linuxserver/htpcmanager:latest	
# Beets helps organize your music
docker run --name=beets -p 8011:8337 -v beets:/config -v $downloadshare/Music:/downloads -v $musicshare:/music -e VIRTUAL_PORT=8011 -e PGID=$pgid -e PUID=$puid -d --restart always --memory="8g" linuxserver/beets
# Glances gives you a web gui for system info
docker run --name=glances -p 8013-8014:61208-61209 -v $dsock -e GLANCES_OPT="-w" --pid host -it -e VIRTUAL_PORT=8013 -d --restart always --memory="1g" docker.io/nicolargo/glances
# Musicbrainz helps beets correct mp3 tags
docker run --name=musicbrainz -p 8015:5000 -e TZ=$TZ -v musicbrainz:/config -v musicbrainz-data:/data -e BRAINZCODE=$bcode -e NPROC=10 -e WEBADDRESS=192.168.1.31 -e VIRTUAL_PORT=8015 -e PGID=$pgid -e PUID=$puid -d --memory="4g" --restart always linuxserver/musicbrainz
# airsonic allows you to stream music and podcasts to multiple devices simultaniously
docker run --name=airsonic -p 8016:4040 -e TZ=$TZ -v airsonic:/config -v $musicshare:/music -v $musicshare/playlists:/playlists -v $musicshare/podcasts:/podcasts -v $musicshare/audiobooks:/media -e VIRTUAL_HOST=music.$extdomain -e VIRTUAL_PORT=4040 -e LETSENCRYPT_HOST=music.$extdomain -e LETSENCRYPT_EMAIL=$lemail -d --restart always --memory="8g" linuxserver/airsonic
############## Weird stuff that breaks if it's not on the right port ##############
# Ubooquity allows your friends to read your ebooks and comics
docker run --name=ubooquity -p 2202:2202 -p 2203:2203 -v ubooquity:/config -v $bookshare:/books -v $comicshare:/comics -v $fileshare:/files -e MAXMEM=8192 -e VIRTUAL_PORT=2202 -e VIRTUAL_HOST=read.$extdomain -e LETSENCRYPT_HOST=read.$extdomain -e LETSENCRYPT_EMAIL=$lemail -e PGID=$pgid -e PUID=$puid -d --restart always --memory="8g" linuxserver/ubooquity:latest

# Transmission + OpenVPN
docker run --name=torrents -p 9091:9091 -p 51413:51413 --cap-add=NET_ADMIN --device=/dev/net/tun -v $downloadshare:/data -v torrents:/config  -v $dtime -e OPENVPN_PROVIDER=$vpnprovider -e OPENVPN_USERNAME=$vpnuser -e OPENVPN_PASSWORD=$vpnpass -e WEBPROXY_ENABLED=false -e LOCAL_NETWORK=192.168.1.0/24 --log-driver json-file --log-opt max-size=10m -d --restart always --memory="8g" haugene/transmission-openvpn


# Filebot sorts movies. This job runs at 9AM Wednesday, sorts movies into movies/genre/name/name.ext then deletes anything left in the unsorted folder
docker pull jorrin/filebot-cli
(crontab -l ; echo "00 09 * * 3 echo docker run --rm -v $mediashare/movies/unsorted:/input -v $mediashare/movies:/output jorrin/filebot-cli filebot -rename -r -non-strict --db themoviedb --output output --format \"{genres[0]}/{n.ascii()} ({y})/{n.ascii()} ({y})\" /input && rm -r $mediashare/movies/unsorted/*") | crontab -

# ebooktools sorts and renames ebooks
docker pull ebooktools/scripts
(crontab -l ; echo "00 09 * * 3 echo docker run --rm -v $bookshare/Unsorted:/unorganized-books -v $bookshare/Sorted:/sorted-books -v $bookshare/SortaSorted:/sorta -v $bookshare/Corrupt:/corrupt -v $bookshare/Pamphlets:/pamphlets ebooktools/scripts:latest organize-ebooks.sh -km -ocr=true -o=/sorted-books -ofu=/sorta -ofc=/corrupt -ofp=/pamphlets /unorganized-books") | crontab -

echo "Creating set up cheat sheet"
echo "This file has most of the information you need to configure the containers that have been set up" > ~/cheat-sheet.txt
echo "External Websites" >> ~/cheat-sheet.txt
echo "	Portainer https://port.$extdomain" >> ~/cheat-sheet.txt
echo "	LazyLibrarian https://lazy.$extdomain" >> ~/cheat-sheet.txt
echo "	Ombi https://ombi.$extdomain" >> ~/cheat-sheet.txt
echo "	HTPC Manager  https://htpc.$extdomain" >> ~/cheat-sheet.txt
echo "	Airsonic  https://music.$extdomain" >> ~/cheat-sheet.txt
echo "	Ubooquity https://read.$extdomain" >> ~/cheat-sheet.txt
echo "" >> ~/cheat-sheet.txt 
echo "Container list" >> ~/cheat-sheet.txt
echo "	Portainer http://$hostip:8001" >> ~/cheat-sheet.txt
echo "	Sonarr http://$hostip:8002" >> ~/cheat-sheet.txt
echo "	Radarr http://$hostip:8003" >> ~/cheat-sheet.txt
echo "	Lidarr http://$hostip:8004" >> ~/cheat-sheet.txt
echo "	Lazy Librarian http://$hostip:8005" >> ~/cheat-sheet.txt
echo "	Hydra2 http://$hostip:8006" >> ~/cheat-sheet.txt
echo "	Jackett http://$hostip:8007" >> ~/cheat-sheet.txt
echo "	NZBGet http://$hostip:8008" >> ~/cheat-sheet.txt
echo "	Ombi http://$hostip:8009" >> ~/cheat-sheet.txt
echo "	HTPC Manager http://$hostip:8010" >> ~/cheat-sheet.txt
echo "	Beets http://$hostip:8011" >> ~/cheat-sheet.txt
echo "	Glances http://$hostip:8013" >> ~/cheat-sheet.txt
echo "	MusicBrainz http://$hostip:8015" >> ~/cheat-sheet.txt
echo "	Airsonic http://$hostip:8016" >> ~/cheat-sheet.txt
echo "	Ubooquity http://$hostip:2202" >> ~/cheat-sheet.txt
echo "	Ubooquity Admin http://$hostip:2203/admin" >> ~/cheat-sheet.txt
echo "	Torrents http://$hostip:9091" >> ~/cheat-sheet.txt 
echo "	Plex http://$hostip:32400" >> ~/cheat-sheet.txt
echo "" >> ~/cheat-sheet.txt 

echo "Container Description and Settings" >> ~/cheat-sheet.txt 
echo "Portainer" >> ~/cheat-sheet.txt 
echo "	Web Interface for Docker Management and log viewing" >> ~/cheat-sheet.txt 
echo "	http://$hostip:8001 or https://port.$extdomain" >> ~/cheat-sheet.txt

echo "" >> ~/cheat-sheet.txt 
echo "Sonarr" >> ~/cheat-sheet.txt 
echo "	Manages TV Shows" >> ~/cheat-sheet.txt 
echo "	http://$hostip:8002" >> ~/cheat-sheet.txt
awk '/ApiKey/' /var/lib/docker/volumes/sonarr/_data/config.xml >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Radarr" >> ~/cheat-sheet.txt 
echo "	Manages Movies" >> ~/cheat-sheet.txt
echo "	http://$hostip:8003" >> ~/cheat-sheet.txt
awk '/ApiKey/' /var/lib/docker/volumes/radarr/_data/config.xml >> ~/cheat-sheet.txt  

echo "" >> ~/cheat-sheet.txt 
echo "Lidarr" >> ~/cheat-sheet.txt
echo "	Manages Music" >> ~/cheat-sheet.txt
echo "	http://$hostip:8004" >> ~/cheat-sheet.txt
awk '/ApiKey/' /var/lib/docker/volumes/lidarr/_data/config.xml >> ~/cheat-sheet.txt   

echo "" >> ~/cheat-sheet.txt 
echo "Lazy Librarian" >> ~/cheat-sheet.txt
echo "	Manages Ebooks" >> ~/cheat-sheet.txt
echo "	http://$hostip:8005" >> ~/cheat-sheet.txt

echo "" >> ~/cheat-sheet.txt 
echo "Hydra2" >> ~/cheat-sheet.txt 
echo "	Manages NZB Indexers" >> ~/cheat-sheet.txt
echo "	http://$hostip:8006" >> ~/cheat-sheet.txt 
awk '/apiKey:/' /var/lib/docker/volumes/hydra2/_data/nzbhydra.yml >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Jackett" >> ~/cheat-sheet.txt 
echo "	Manages Torrent Indexers" >> ~/cheat-sheet.txt
echo "	http://$hostip:8007" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "NZBGet" >> ~/cheat-sheet.txt 
echo "	Downloads NZB Files" >> ~/cheat-sheet.txt
echo "	http://$hostip:8008" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Ombi" >> ~/cheat-sheet.txt 
echo "	Provides an interface for Plex users to use Sonarr, Radarr, and Lidarr" >> ~/cheat-sheet.txt
echo "	http://$hostip:8009 or https://ombi.$extdomain" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "HTPC Manager" >> ~/cheat-sheet.txt 
echo "	Provides an interface for connecting to apps externally" >> ~/cheat-sheet.txt
echo "	http://$hostip:8010 or https://htpc.$extdomain" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Beets" >> ~/cheat-sheet.txt 
echo "	Fixes MP3 tags" >> ~/cheat-sheet.txt
echo "	http://$hostip:8011" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Glances" >> ~/cheat-sheet.txt 
echo "	Resource Dashboard for your Docker Server" >> ~/cheat-sheet.txt
echo "	http://$hostip:8013" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "MusicBrainz" >> ~/cheat-sheet.txt 
echo "	Provides Music metadata to Beets" >> ~/cheat-sheet.txt
echo "	http://$hostip:8015" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Airsonic" >> ~/cheat-sheet.txt 
echo "	Music Server and Podcast downloader" >> ~/cheat-sheet.txt
echo "	http://$hostip:8016 or https://music.$extdomain" >> ~/cheat-sheet.txt

echo "" >> ~/cheat-sheet.txt 
echo "Ubooquity" >> ~/cheat-sheet.txt 
echo "	Ebook Server and Downloader" >> ~/cheat-sheet.txt
echo "	http://$hostip:2202 or https://read.$extdomain" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Ubooquity Administration" >> ~/cheat-sheet.txt 
echo "	Admin interface for Ubooquity" >> ~/cheat-sheet.txt
echo "	http://$hostip:2203/admin " >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Torrents" >> ~/cheat-sheet.txt 
echo "	Torrent Downloader with OpenVPN built in" >> ~/cheat-sheet.txt
echo "	http://$hostip:9091" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Nginx-proxy" >> ~/cheat-sheet.txt
echo "Proxies connections to allow everything to be reachable from the docker host IP" >> ~/cheat-sheet.txt  

echo "" >> ~/cheat-sheet.txt 
echo "letsencrypt-nginx-proxy-companion" >> ~/cheat-sheet.txt
echo "	Automatically gets and renews SSL Certificates" >> ~/cheat-sheet.txt 

echo "" >> ~/cheat-sheet.txt 
echo "Watchtower" >> ~/cheat-sheet.txt
echo "	Updates and restarts containers when a new image is released" >> ~/cheat-sheet.txt



echo "Please open the following pages and create passwords immediatly. These are externally exposed, so should have secure passwords."
echo "Portainer is available at $hostip:8001 or https://port.$extdomain"
echo "LazyLibrarian is available at $hostip:8005 or https://lazy.$extdomain"
echo "Ombi is available at $hostip:8009 or https://ombi.$extdomain"
echo "HTPC Manager is available at $hostip:8010 or https://htpc.$extdomain"
echo "Airsonic is available at $hostip:8016 or https://music.$extdomain"
echo "Ubooquity's admin interface is available at $hostip:2203/admin"
echo "NZBGet's defaults are login:nzbget, password:tegbzn6789"
echo "There is other useful config information at ~/cheat-sheet.txt"

fi



































