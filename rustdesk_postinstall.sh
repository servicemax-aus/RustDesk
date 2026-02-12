#!/bin/bash

agent_file='https://raw.githubusercontent.com/servicemax-aus/RustDesk/refs/heads/main/agent.plist'
daemon_file='https://raw.githubusercontent.com/servicemax-aus/RustDesk/refs/heads/main/daemon.plist'
scriptname="RustDesk Service Installer"
logandmetadir="/Library/Application Support/Servicemax/rustdesk"
log="$logandmetadir/rustdeskServiceInstaller.log"
agent_path='/Library/LaunchAgents/com.servicemax.rdesk_server.plist'
daemon_path='/Library/LaunchDaemons/com.servicemax.rdesk_service.plist'
current_user=$(dscacheutil -q user | grep -A 3 -B 2 -e uid:\ 501 | awk '/name: /{print $2}')

function install_as_service {

tmp_daemon="/tmp/com.servicemax.rdesk_service.plist"
tmp_agent="/tmp/com.servicemax.rdesk_server.plist"

curl -fsSL "$daemon_file" -o "$tmp_daemon" || exit 1
curl -fsSL "$agent_file"  -o "$tmp_agent"  || exit 1

install -o root -g wheel -m 644 "$tmp_daemon" /Library/LaunchDaemons/com.servicemax.rdesk_service.plist
install -o root -g wheel -m 644 "$tmp_agent"  /Library/LaunchAgents/com.servicemax.rdesk_server.plist

launchctl bootstrap system /Library/LaunchDaemons/com.servicemax.rdesk_service.plist
launchctl bootstrap gui/501 /Library/LaunchAgents/com.servicemax.rdesk_server.plist


    if [ -f $agent_path ]; then
        echo "Agent file exists"
        echo "Launching Server"
        launchctl enable "gui/501/com.servicemax.rdesk_server"
		launchctl kickstart -kp "gui/501/com.servicemax.rdesk_server"

        fi
}

## Check if the log directory has been created and start logging
if [ -d "$logandmetadir" ]; then
    ## Already created
    echo "# $(date) | Log directory already exists - "$logandmetadir""
else
    ## Creating Metadirectory
    echo "# $(date) | creating log directory - "$logandmetadir""
    mkdir -p "$logandmetadir"
fi

# start logging
exec 1>> "$log" 2>&1

# Begin Script Body

echo ""
echo "##############################################################"
echo "# $(date) | Starting $scriptname"
echo "############################################################"
echo ""

while [ ! -d "/Applications/ServicemaxRemoteSupport.app" ]; do
    echo ""
    echo "RustDesk is not installed"
    echo "Checking again in 30 seconds"
    echo ""
    echo ""
    sleep 30
done

if [ $(launchctl print system/com.servicemax.rdesk_service 2> /dev/null | awk '$1 ~ /^state/ {print$3}') = "running" ] 2>/dev/null; then
    echo ""
    echo "com.servicemax.rdesk_service is already running"
    exit 0
fi

echo "*********** RUSTDESK IS INSTALLED ***********"
echo "******* STARTING SERVICE INSTALLATION *******"
install_as_service
