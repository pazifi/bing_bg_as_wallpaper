#!/bin/bash

# Download background image from bing
# and install it as background wallpaper of kde desktop

# 2019.??.?? - Created
# 2020.07.19 - Waiting for Inet connection and logging
# 2025.04.03 - Little bit cleanup

#######################################################################
# Configuration
#######################################################################

# Valid options: "_1024x768" "_1280x720" "_1366x768" "_1920x1200" 
RES="_1920x1200"
ARCH_DIR=${HOME}/bin/wallpaper/archive/
TIMEOUT=120

#######################################################################
# Functions
#######################################################################
function log {
	echo ${1}
	logger -t "$(basename $0)[$$]" ${1};
}

#######################################################################
# Main
#######################################################################

log "Waiting for internet connection"
while ! ping -4 -c 1 -n -w 1 www.bing.com &> /dev/null; do
	(( TIMEOUT-- ))
	if [ ${TIMEOUT} -lt 0 ]; then
		log "Timeout"
		exit 0
 	fi
	sleep 1
done

# get information about picture from bing webside
log "try download picture"
if ! URL=$(curl -s "http://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt=en-WW" | sed -n 's:.*<urlBase>\(.*\)</urlBase>.*:\1:p'); then
	log "can not read picture information"
	exit 1
fi

# destination path for picture
PICTURE="${URL#/th?id=OHR.}${RES}.jpg"

# download picture
if ! wget http://www.bing.com/${URL}${RES}.jpg -O ${ARCH_DIR}${PICTURE}; then
	log "Can not download picture"
	exit 1;
fi

# Install picture as wallpaper in KDE
log "install picture \"${PICTURE}\" as wallpaper on all desktops"
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:
var Desktops = desktops();                                                                                                                       
for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        d.wallpaperPlugin = \"org.kde.image\";
        d.currentConfigGroup = Array(\"Wallpaper\",
                                    \"org.kde.image\",
                                    \"General\");
        d.writeConfig(\"Image\", \"file://${PICTURE}\");
}"
