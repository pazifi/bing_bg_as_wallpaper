#!/bin/bash

# Download background image from bing
# and install it as background wallpaper of kde desktop

# 2019.??.?? - Created
# 2020.07.19 - Waiting for Inet connection and logging

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
	logger -t "$(basename $0)[$$]" ${1};
}

#######################################################################
# Main
#######################################################################

log "Waiting for internet connection"
while ! ping -4 -c 1 -n -w 1 www.bing.com &> /dev/null; do
	(( TIMEOUT-- ))
	if [ $TIMEOUT -lt 0 ]; then
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

# download picture
if ! wget http://www.bing.com/$URL$RES.jpg -P $ARCH_DIR; then
	log "Can not download picture"
	exit 1;
fi

# rename special characters in path (dirty)
for i in $(ls -1hrt $ARCH_DIR  ); do if [[ $i  == *"th?id=OHR."* ]]; then mv $ARCH_DIR/$i  $ARCH_DIR/${i#"th?id=OHR."} ; fi   ; done

# path of the latest picture
PIC=$ARCH_DIR/$(ls -1hrt $ARCH_DIR | tail -n1)

log "install picture \"${PIC}\" as wallpaper on all desktops"
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:
var Desktops = desktops();                                                                                                                       
for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        d.wallpaperPlugin = \"org.kde.image\";
        d.currentConfigGroup = Array(\"Wallpaper\",
                                    \"org.kde.image\",
                                    \"General\");
        d.writeConfig(\"Image\", \"file://${PIC}\");
}"
