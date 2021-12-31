#!/bin/sh
set -xve

# Test using the following form:
# export SANED_NET_HOSTS="a|b" AIRSCAN_DEVICES="c|d" DELIMITER="|"; ./run.sh

# turn off globbing
set -f

# split at newlines only (airscan devices can have spaces in)
IFS='
'

# Get a custom delimiter but default to ;
DELIMITER=${DELIMITER:-;}

# Insert a list of net hosts
if [ ! -z "$SANED_NET_HOSTS" ]; then
  hosts=$(echo $SANED_NET_HOSTS | sed "s/$DELIMITER/\n/")
  for host in $hosts; do
    echo $host >> /etc/sane.d/net.conf
  done
fi

# Insert airscan devices
if [ ! -z "$AIRSCAN_DEVICES" ]; then
  devices=$(echo $AIRSCAN_DEVICES | sed "s/$DELIMITER/\n/")
  for device in $devices; do
    sed -i "/^\[devices\]/a $device" /etc/sane.d/airscan.conf
  done
fi

# Check if dbus needs to be restarted
if [ ! -z "$DBUS_WORKAROUND" ]; then
  workaround=$(echo $DBUS_WORKAROUND)
  if [ "$workaround" = "true" ]; then
    STATUS="$(service dbus status > /dev/null || echo 'dbus not running')"
    if [ "${STATUS}" = "dbus not running" ]; then
      echo "Restarting dbus. This may take a while... "
      service dbus stop
      if [ -f "/var/run/dbus/system_bus_socket" ]; then
        rm /var/run/dbus/system_bus_socket
      fi
      service dbus start
      echo "dbus restarted"
    else
      echo "No need to restart dbus"
    fi
  fi
fi

if [ ! -z ${INSTALL_HP_PLUGIN} ]; then
    echo "Setting up HP drivers..."
    bash /setup_scripts/hp_drivers.sh
fi

unset IFS
set +f

node ./server/server.js
