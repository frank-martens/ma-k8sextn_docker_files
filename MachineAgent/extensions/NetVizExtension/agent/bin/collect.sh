#!/bin/sh

# Setup PATH environment variable to have paths required by our scripts.
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:

SCRIPT="$0"

# SCRIPT may be an arbitrarily deep series of symlinks.
# Loop until we have the concrete path.
while [ -h "$SCRIPT" ] ; do
	ls=`ls -ld "$SCRIPT"`
	# Drop everything prior to ->
	link=`expr "$ls" : '.*-> \(.*\)$'`
	if expr "$link" : '/.*' > /dev/null; then
		SCRIPT="$link"
	else
		SCRIPT=`dirname "$SCRIPT"`/"$link"
	fi
done

# determine npm root directory
NPM_ROOT_DIR="`dirname "$SCRIPT"`/.."

# make NPM_ROOT_DIR absolute
NPM_ROOT_DIR="`cd "$NPM_ROOT_DIR"; pwd`"
NPM_LOG_DIR="${NPM_ROOT_DIR}/logs"
NPM_CONF_DIR="${NPM_ROOT_DIR}/conf"
NPM_HOME_DIR="${NPM_ROOT_DIR}/home/"

# Destination folder where to store all the collected logs
DEST="`pwd`"
DEST_NAME=""
DEST_DIR=""

# Option Flags
COLLECT_METRICS=0
CREATE_ZIP=0

# Time for collecting
TIME_TO_COLLECT="30s"
DO_SLEEP=0

HOSTNAME=$(hostname)
TIME=$(date +%s)

OPTSTRING='hp:t:m:z'
usage () {
	echo "This script is used for collecting debug data for netagent."
	echo "Usage: $0 [-h] [-p path] [-m] [-t time] [-c] [-z]"
	echo "-h		print command line options"
	echo "-p		path for storing the collected data"
	echo "-m		collect metrics for specified time. Sudo req. "
	echo "-t		time for collecting metric data."
	echo "  		Defaults to 30s "
	echo "-z		Create a zip file for collected data. By"
	echo "  		default creates a tar file"
}

# Creates the dir where to move all the debug info
_create_dest_dir() {
	mkdir $DEST_DIR
	if [ $? -eq 0 ]; then
		echo "Starting log collection in dir: ${DEST_DIR}"
	else
		echo "The dest directory can't be created. Exiting"
		exit 1
	fi
}

# Checks that the user running the script has root privileges.
_check_user() {
	# Check that the script is run as root
	if [ "$(id -u)" != "0" ]; then
		echo "The script needs root privilege for these options"
		exit 1
	fi
}

# Trigger start or stop of metric dumping in metric log file.
# Sudo/root privilege is required
_trigger_metrics_log() {
	echo "Signalling metric dump $1 in netagent"
	kill -USR1 `pgrep appd-netagent`	
	if [ $? -ne 0 ]; then
		echo "Issues collecting the metrics. Check permissions."
		exit 1
	fi
}

_sleep() {
	echo "Sleeping for ${TIME_TO_COLLECT}"
	sleep $TIME_TO_COLLECT
	echo "Waking up from sleep"
}

_collect_logs() {
	echo "Collecting netagent Logs"
	cp -r $NPM_LOG_DIR $DEST_DIR
}

_collect_conf() {
	echo "Collecting netagent Conf"
	cp -r $NPM_CONF_DIR $DEST_DIR
}

_collect_home() {
	echo "Collecting netagent home dir"
	cp -r $NPM_HOME_DIR $DEST_DIR
}

_create_tar() {
		TAR_FILE="${DEST_NAME}.tar"
		echo "Compressing the collected files into tar ${TAR_FILE}"
		echo "Loc of tar ${DEST_DIR}${TAR_FILE}"
		cd $DEST && tar -cvf $DEST_DIR$TAR_FILE $DEST_NAME 1>/dev/null
}

_create_zip() {
		ZIP_FILE="${DEST_NAME}.zip"
		echo "Compressing the collected files into a zip"
		echo "Loc of zip ${DEST_DIR}${ZIP_FILE}"
		cd $DEST && zip -r $DEST_DIR$ZIP_FILE $DEST_NAME 1>/dev/null
}

_run_tasks() {
	_create_dest_dir
	if [ $COLLECT_METRICS -eq 1 ]; then
		echo "Collecting metric dump in netagent"
		_trigger_metrics_log "start"
	fi
	if [ $DO_SLEEP -eq 1 ]; then
		_sleep
	fi
	if [ $COLLECT_METRICS -eq 1 ]; then
		_trigger_metrics_log "stop"
	fi

	_collect_logs
	_collect_conf
	_collect_home

	if [ $CREATE_ZIP -eq 1 ]; then
		_create_zip
	else
		_create_tar
	fi
}


while getopts "$OPTSTRING" OPTION $ARGV; do
	case "$OPTION" in
		p)
			DEST=$OPTARG
			;;
		h) 
			usage
			exit 0
			;;
		m)
			DO_SLEEP=1
			COLLECT_METRICS=1
			;;
		t)
			TIME_TO_COLLECT=$OPTARG
			;;
		z)
			CREATE_ZIP=1
			;;
		*)
			exit 1
			;;
	esac
done

DEST="`cd "$DEST"; pwd`"
DEST_NAME="${HOSTNAME}-${TIME}"
DEST_DIR="${DEST}/${DEST_NAME}/"

_run_tasks
