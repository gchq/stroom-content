
# Release 1.1  - 20180411 Burn Alting - burn@swtf.dyndsn.org
#   - Correct minor script errors
# Release 1.0  - 20170623 Burn Alting - burn@swtf.dyndns.org
#   - Initial Release

# This script 
#   - on start up delays for a random period of time before proceeding. This is intended to
#     inject random transmission load across a network of many systems generating audit.
#   - calls '/usr/sbin/squid -k rotate' to cause squid to rotate it's log files
#   - processes all rotated logs via the supporting squidplusXML.pl perl script leaving files in a queue directory
#   - concatenate all raw logs into /var/log/squid/access.log
#   - compresses then attempts to post the logs from the queue directory and removes them from the queue directory on successful post
#
# Note this script will need to change if it is to support multiple Squid instances.


# USAGE:
#   stroom_feeder.sh [-n]
#   -n         prevents the random sleep prior to processing
#
Usage="Usage: `basename $0` [-n]"

Arg0=`basename $0`
LCK_FILE=/tmp/$Arg0.lck		# Note safe if multiple scripts execute at same time
THIS_PID=`echo $$`

# We should normally sleep before processing data
NoSleep=0

# Check args
while getopts "n" opt; do
  case $opt in
  n)
    NoSleep=1
    ;;
  \?)
    echo "$0: Invalid option -$OPTARG"
    echo $Usage
    exit 1
    ;;
 esac
done

# SYSTEM            - Name of System
SYSTEM="My Squid Service"

# ENVIRONMENT       - Application environment
# Can be  Production, QualityAssurance or Development
ENVIRONMENT="Production"

# URL               - URL for posting gzip'd audit log files
#
# This should NOT change without consultation with Audit Authority
URL=https://stroomp00.strmdev00.org/stroom/datafeed

# mySecZone     - Security zone if pertinant
#
# We set this typically externally to the base script script source
mySecZone="none"

# VERSION           - The version of the log source
#
# This is to allow one to distinguish between different versions of the capability
# generating logs. If you have strong version control on the logging element of
# your application, you can use your release of the installed utility version.
# Samples are
#   Basic extraction from a rpm package
#       VERSION=`rpm -q httpd`
#UBUNTU VERSION=`dpkg --status squid | awk '{if ($1 == "Version:") print $2;}'`
VERSION=`rpm -q squid`


# FEED_NAME         - Name of Stroom feed (asssigned by Audit Authority)
#
# This is the Stroom feed name we post the collected audit events to.
FEED_NAME="Squid-Plus-XML-V1.0-EVENTS"

# FAILED_RETENTION  - Retention period to hold logs that failed to transmit (days)
#
# This period, in days, is to allow a log source to temporarily maintain local copies
# of failed to transmit logs.
FAILED_RETENTION=90

# FAILED_MAX        - Specify a storage limit on logs that failed to transmit (512-byte blocks)
#
# As well as a retention period for logs that failed to transmit, we also
# limit the size of this archive in terms byte.
# The value is in 512-byte blocks rather than bytes
# For example, 1GB is 
#   1 GiB = 1 * 1024 * 2048 = 2097152
#   8 GiB = 8 * 1024 * 2048 = 16777216
FAILED_MAX=16777216

# MAX_SLEEP         - Time to delay the processing and transmission of logs
#
# To avoid audit logs being transmitted from the estate at the same time, we will
# delay a random number of seconds up to this maximum before processing and
#
# This value should NOT be changed with permission from Audit Authority. It should
# also be the periodicity of the calling of the feeding script. That is, cron
# should call the feeding script every MAX_SLEEP seconds
MAX_SLEEP=580

# C_TMO             - Maximum time in seconds to allow the connection to the server to take
C_TMO=37

# M_TMO             - Maximum time in seconds to allow the whole operation to take
M_TMO=1200

# STROOM_LOG_SOURCE    - Source location of logs
# STROOM_LOG_QUEUED    - Directory to queue logs ready for transmission
# PrimaryLog           - Filename of main log file
STROOM_LOG_SOURCE=/var/log/squid/squidCurrent
STROOM_LOG_QUEUED=/var/log/squid/squidlogQueue
PrimaryLog=/var/log/squid/access.log

# ROUTINES:

# clean_store()
# Args:
#  $1 - root      - the root of the archive directory to clean
#  $2 - retention - the retention period in days before archiving
#  $3 - maxsize   - the maximum size in (512-byte) blocks allowed in archive
#
# Ensure any local archives of logs are limited in size and retention period
clean_store()
{
  if [ $# -ne 3 ] ; then
    echo "$Arg0: Not enough args calling clean_archive()"
    return
  fi
  root=$1
  retention=$2
  maxsize=$3

  # Just to be paranoid
  if [ ${root} = "/" ]; then
      echo "$Arg0: Cannot clean_archive root filesystem"
      return
  fi

  # We first delete files older than the retention period
  find ${root} -type f -mtime +${retention} -exec rm -f {} \;

  # First cd to ${root} so we don't need shell expansion on
  # the ls command below.
  myloc=`pwd`
  cd ${root}
  # We next delete based on the max size for this store
  s=`du -s --block-size=512 . | cut -f1`
  while [ ${s} -gt ${maxsize} ]; do
    ls -t | tail -5 | xargs rm -f
    s=`du -s --block-size=512 . | cut -f1`
  done
  cd ${myloc}
  return
}

# logmsg()
# Args:
#   $* - arguements to echo
#
# Print a message prefixed with a date and the program name
logmsg() {
  NOW=`date  +"%FT%T.000%:z"`
  echo "${NOW} ${Arg0} `hostname`: $*"
}

# stroom_get_lock()
# Args:
#   none
#
# Obtain a lock to prevent duplicate execution
stroom_get_lock() {

  if [ -f "${LCK_FILE}" ]; then
    MYPID=`head -n 1 "${LCK_FILE}"`
    TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`

    if [ -z "${TEST_RUNNING}" ]; then
      logmsg "Obtained lock for ${THIS_PID}"
      echo "${THIS_PID}" > "${LCK_FILE}"
    else
      logmsg "Sorry ${Arg0} is already running[${MYPID}]"
      # If the lock file is over thee hours old remove it. Basically remove clearly stale lock files
      find ${LCK_FILE} -mmin +180 -exec rm -f {} \;
      exit 0
    fi
  else
    logmsg "Obtained lock for ${THIS_PID} in ${LCK_FILE}"
    echo "${THIS_PID}" > "${LCK_FILE}"
  fi
}

# stroom_rm_lock()
# Args:
#   none
#
# Remove lock file

stroom_rm_lock() {
  if [ -f ${LCK_FILE} ]; then
    logmsg "Removed lock ${LCK_FILE} for ${THIS_PID}"
    rm -f ${LCK_FILE}
  fi
}

# send_to_stroom()
# Args:
#  $1 - the log file
#
# Send the given log file to the Stroom Web Service.

send_to_stroom() {
  logFile=$1
  logSz=`ls -sh ${logFile} | cut -d' ' -f1`

  # Create a string of local metadata for transmission. We start with the shar and filename. Note we can only
  # have arguments added to the string if we can be assured they do not have embedded spaces
  hostArgs="-H Shar256:`sha256sum -b ${logFile} | cut -d' ' -f1` -H LogFileName:`basename ${logFile}`"
  myHost=`hostname --all-fqdns 2> /dev/null`
  if [ $? -ne 0 ]; then
    myHost=`hostname`
  fi
  myIPaddress=`hostname --all-ip-addresses 2> /dev/null`

  myDomain=`hostname -d 2>/dev/null`
  if [ -n "${myDomain}" ]; then
    myNameserver=`dig ${myDomain} SOA +time=3 +tries=2 +noall +answer +short 2>/dev/null | head -1 | cut -d' ' -f1`
    if [ -n "$myNameserver" ]; then
      hostArgs="${hostArgs} -H MyNameServer:\"${myNameserver}\""
    else
      # Let's try dumb and see if there is a name server in /etc/resolv.conf and choose the first one
      h=`egrep '^nameserver ' /etc/resolv.conf | head -1 | cut -f2 -d' '`
      if [ -n "${h}" ]; then
        h0=`host $h 2> /dev/null | gawk '{print $NF }'`
        if [ -n "${h0}" ]; then
           hostArgs="${hostArgs} -H MyNameServer:\"${h0}\""
        elif [ -n "${h}" ]; then
           hostArgs="${hostArgs} -H MyNameServer:\"${h}\""
        fi
      fi
    fi
  fi
  # Gather various configuration details via facter(1) command if available
  if hash facter 2>/dev/null; then
    # Redirect facter's stderr as this script may not be running as root
    myMeta=`facter 2> /dev/null | awk '{
if ($1 == "fqdn") printf "FQDN:%s\\\n", $3;
if ($1 == "uuid") printf "UUID:%s\\\n", $3;
if ($1 ~ /^ipaddress/) printf "%s:%s\\\n", $1, $3;
}'`
    if [ -n "${myMeta}" ]; then
      hostArgs="${hostArgs} -H MyMeta:\"${myMeta}\""
    fi
  fi
  # Local time zone
  ltz=`date +%z`
  if [ -n "${ltz}" ]; then
      hostArgs="${hostArgs} -H MyTZ:${ltz}"
  fi

  # Do the transfer.

  # For two-way SSL authentication replace '-k' below with '--cert /path/to/server.pem --cacert /path/to/root_ca.crt' on the curl cmds below

  # If not two-way SSL authentication, use the -k option to curl
  if [ -n "${mySecZone}" -a "${mySecZone}" != "none" ]; then
    RESPONSE_HTTP=`curl -k --connect-timeout ${C_TMO} --max-time ${M_TMO} --data-binary @${logFile} ${URL} \
-H "Feed:${FEED_NAME}" -H "System:${SYSTEM}" -H "Environment:${ENVIRONMENT}" -H "Version:${VERSION}" \
-H "MyHost:\"${myHost%"${myHost##*[![:space:]]}"}\"" \
-H "MyIPaddress:\"${myIPaddress%"${myIPaddress##*[![:space:]]}"}\"" \
-H "MySecurityDomain:\"${mySecZone%"${mySecZone##*[![:space:]]}"}\"" \
${hostArgs} \
-H "Compression:GZIP" --write-out "RESPONSE_CODE=%{http_code}" 2>&1`
  else
    RESPONSE_HTTP=`curl -k --connect-timeout ${C_TMO} --max-time ${M_TMO} --data-binary @${logFile} ${URL} \
-H "Feed:${FEED_NAME}" -H "System:${SYSTEM}" -H "Environment:${ENVIRONMENT}" -H "Version:${VERSION}" \
-H "MyHost:\"${myHost%"${myHost##*[![:space:]]}"}\"" \
-H "MyIPaddress:\"${myIPaddress%"${myIPaddress##*[![:space:]]}"}\"" \
${hostArgs} \
-H "Compression:GZIP" --write-out "RESPONSE_CODE=%{http_code}" 2>&1`
  fi

  # We first look for a positive response (ie 200)
  RESPONSE_CODE=`echo ${RESPONSE_HTTP} | sed -e 's/.*RESPONSE_CODE=\(200\).*/\1/'`
  if [ "${RESPONSE_CODE}" = "200" ] ;then
    logmsg "Send status: [${RESPONSE_CODE}] SUCCESS  Audit Log: ${logFile} Size: ${logSz} ProcessTime: ${ProcessTime} Feed: ${FEED_NAME}"
    rm -f ${logFile}
    return 0
  fi

  # If we can't find it in the output, look for the last response code
  # We do this in the unlikely event that a corrupted arguement is passed to curl
  RESPONSE_CODE=`echo ${RESPONSE_HTTP} | sed -e 's/.*RESPONSE_CODE=\([0-9]\+\)$/\1/'`
  if [ "${RESPONSE_CODE}" = "200" ] ;then
    logmsg "Send status: [${RESPONSE_CODE}] SUCCESS  Audit Log: ${logFile} Size: ${logSz} ProcessTime: ${ProcessTime}"
    rm -f ${logFile}
    return 0
  fi

  # Fall through ...

  # We failed to tranfer the processed log file, so emit a message to that effect
  msg="Send status: [${RESPONSE_CODE}] FAILED  Audit Log: ${logFile} Reason: curl returned http_code (${RESPONSE_CODE})"
  logmsg "$msg"
   
  # We also send an event into the security syslog destination
  logger -p "authpriv.info" -t $Arg0 "$msg"

  return 9
}

# MAIN:

# Set up a delay of between 7 - $MAX_SLEEP seconds
# The additional 7 seconds is to allow for log acqusition time

RANDOM=`echo ${RANDOM}`
MOD=`expr ${MAX_SLEEP} - 7`
SLEEP=`expr \( ${RANDOM} % ${MOD} \) + 7`

# Get a lock
stroom_get_lock

# Create queue directory if need be
if [ ! -d ${STROOM_LOG_QUEUED} ]; then mkdir -p ${STROOM_LOG_QUEUED}; fi

# We may need to sleep
if [ ${NoSleep} -eq 0 ]; then
  logmsg "Will sleep for ${SLEEP}s to help balance network traffic"
  sleep ${SLEEP}
fi

# We now collect the logs from the source and move them
# into our queueing directory

# Squid logs that have rolled over are of the form
# 	squid.log.N
# in our log source directory. So we need to rotate the logs
# then move all logs to the queue directory with a unique tag. As we
# move the logs we also want to concatentate the logs onto
# /var/log/squid/access.log

uTag=`date +%s`
cd ${STROOM_LOG_SOURCE}
/usr/sbin/squid -k rotate
# Sleep a bit for the rotate to occur
sleep 2
l=`ls access.log.* 2>/dev/null | sort --key=3 --field-separator=\. --reverse --numeric-sort`
if [ ! -z "${l}" ]; then
  for f in ${l}; do
    if [ -s $f ]; then
      ./squidplusXML.pl < ${f} > ${STROOM_LOG_QUEUED}/${uTag}.${f}
      # Concatenate onto primarylog file
      cat ${f} >> ${PrimaryLog} && rm -f ${f}
    else 
      # Remove empty files
      rm -f ${f}
    fi
  done
fi

# Go to the queue directory and post
cd ${STROOM_LOG_QUEUED}
# Gzip any non-gziped files
l=`find . -type f -regextype sed ! -regex "./[0-9]\+.*.gz$"`
if [ ! -z "$l" ]; then
  echo $l | xargs gzip --force
fi

for f in `find . -type f -regextype sed -regex "./[0-9]\+.*.gz$"`; do

  if [ -s ${f} ]; then
    export ProcessTime=0
    send_to_stroom ${f}
  else
    rm -f ${f}
 fi
done

clean_store ${STROOM_LOG_QUEUED} ${FAILED_RETENTION} ${FAILED_MAX}
stroom_rm_lock
exit 0
