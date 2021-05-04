#!/bin/bash

# Release 1.5  - 20190214 Burn Alting - burn@swtf.dyndns.org
#   - Rename script to be in line with as yet to be released stroom "agents"
#   - Add options to specify certificate details to curl in the event of requiring two sided trust
#   - Add the collection of the IANA timezone name
# Release 1.4  - 20180411 Burn Alting - burn@swtf.dyndns.org
#   - Corrected some simple scripting errors
#
# Release 1.3  - 20180205 Burn Alting - burn@swtf.dyndns.org
#   - Add an archiving option (that is, archive the files posted)
#
# Release 1.2  - 20180124 Burn Alting - burn@swtf.dyndns.org
#   - Allow the insertion of a delay between posts if multiple files
#   - Allow for a specifi lock file template
#
# Release 1.1  - 20171125 Burn Alting - burn@swtf.dyndns.org
#   - Improve file name generation and compression in the queue directory
#   - Add some more documentation
#   - Cater for the absence of bind-utils utilitie - host(1)
#
# Release 1.0  - 20171008 Burn Alting - burn@swtf.dyndns.org
#   - Initial Release

# Stroom audit posting script

# It is preferred that the bind-utils utilities are installed

# This script
#   - on start up delays for a random period of time before proceeding. This is intended to
#     inject random transmission load across a network of many systems generating audit. It is expected that this script
#     run every 10 minutes. If you change this, then change the variable $MAX_SLEEP below to be 20 or so second below the execution periodicity.
#   - finds all files in the given 'eventsdir' which match the regular expression 'logfileprefix'.*'logfixsuffix' and either
#     concatenates the files into a single file (if -C is given) or copies them to the 'queuedir' directory.
#   - compresses all files in 'queuedir' (if not compressed)
#   - attempts to post the compressed files and removes them from the queue directory on successful post. If the post fails, the files are
#     left in place for the next invocation. An optional delay can be inserted between posting files and the posted files can be optionally archived.
#   - if the total aggregated files in 'queuedir' have a size greater than the variable $FAILED_MAX then the oldest files in 'queuedir' are
#     removed until the total size is less than $FAILED_MAX. This is to prevent the queue directory filling it's filesystem based on size.
#   - if the files in 'queuedir' become older than $FAILED_RETENTION days, then they are removed. This is to prevent the queue directory filling it's
#     filesystem based on time of files.
#
# NOTE: If you need to maintain the original filename when posting to Stroom you should NOT use the -C parameter
# Even then, you will need to 'unwrap' the original filename by striping off the '<epoch>.' and '._StroomPost_events.gz'
# from the file <epoch>.originalfilename._StroomPost_events.gz

# It is expected that the system generating the files containing audit
#	- place the files in a given directory. We specify the directory with the -S 'eventsdir' argument
#	- the files have a certain nomenclature with a file name 'prefix' and 'suffix'. If the 'prefix' is not consistent, then hopefully
#         the 'suffix' is. For example, the files might have the nomenclature '<sometimestamp>.log' in this case we can identify the 'suffix' as
#         '.log'. Others may have the nomenclature of 'application_A.<somenumber>.events' and in this case we can identify the
#          'prefix' of 'application_A' and the suffix of '.events'.
# The audit authority will provide you with
#	- a 'feedname' to label the audit you are sending
#	- a 'URL' to post the audit to
#	- a recommendation on the 'environment' to use (e.g. 'Production', 'Development', etc)
#	- a recommendation on the 'system' generating the audit
#	- a recommendation on the 'version' of audit being generated
#	- a recommendation on the 'securityzone' you are running within
#
# Defaults are
#	eventsdir	'/var/log/someapplication'
#	queuedir	'/var/log/someapplication/queue'
#       archivedir      ''
#	feedname	'SomeApplication-V3.0-EVENTS'
#	URL		'https://stroomp00.strmdev00.org/stroom/datafeed'
#	environment	'Production'
#	system		'My Stroom Capability'
#	logfileprefix	<null>
#	logfixsuffix	'.log'
#	version		'V1.0'
#	securityzone	'none'
#	NoSleep		0 (ie we sleep for a random number of seconds up to MAX_SLEEP)
#	AllowConcatenation	0 (we don't concatenate available files into one file for posting, i.e. we post individual files)
#	NoDelay		0 (we don't delay between posts)
#	LckTemplate	'' (empty lock file template)

# USAGE:
#   <app>_stroom_feeder.sh [-nC] [-S eventsdir] [-Q queuedir] [-F feedname] [-U URL] [-E environment] [-s system] [-0 logfileprefix] [-1 logfixsuffix] [-V version] [-Z securityzone] [-d delaysecs] [-l lockFileTemplate] [-A archivedirectory] [-c cacert -p clientcert]
#   -c  specify CA certificate file (value becomes curl --cacert option argument)
#   -d  specify the number of seconds between posting files
#   -l  lockfilename template
#   -p  specify the client certificate file (pem format) to use when posting (value becomes curl --cert option argument)
#   -n  prevents the random sleep prior to processing
#   -A  identify an optional archive directory (that is archive the files posted)
#   -C  allow concatenation of event files in collection directory
#   -S	identify a different source directory
#   -Q  identify a different queue directory
#   -F  identify a different feed name
#   -U  identify a different URL
#   -E  identify a different Environment
#   -s  identify a different System
#   -V  identify a different Version string
#   -Z  identify a different Security Zone
#   -0  logfile prefix
#   -1  logfile suffix
#
Usage="Usage: `basename $0` [-nC] [-S eventsdir] [-Q queuedir] [-A archivedir] [-F feedname] [-U URL] [-E environment] [-s system] [-0 logfileprefix] [-1 logfilesuffix] [-V newversion] [-Z newsecurityzone] [-d delaysecs] [-l lockFileTemplate] [-c cacert -p clientcert]"

Arg0=`basename $0`
LCK_FILE=/tmp/$Arg0.lck		# Not safe if multiple scripts execute at same time (use -l to support multiple invocations)
THIS_PID=`echo $$`

# We should normally sleep before processing data
NoSleep=0

# We normally don't delay between posts
NoDelay=0

# Lock file template
LckTemplate=$Arg0

# Allow concatenation of source event files
AllowConcatenation=0
# New source directory
NewSource=''
# New queue directory
NewQueue=''
# New Feed name
NewFeed=''
# New URL destination
NewURL=''
# New Environment
NewEnvironment=''
# New System
NewSystem=''
# New Version
NewVersion=''
# New security Zone
NewMySecZone=''

# Archive directory is null (no archive) by default
ARCHIVE=''

# Log file
# Prefix and Suffix
Prefix=''
Suffix='.log'

# Certificate detail
cacert=''
cert=''

# Check args
while getopts "nCS:Q:A:F:U:E:V:Z:d:l:s:0:1:c:p:" opt; do
  case $opt in
  c)
    cacert=$OPTARG
    ;;
  p)
    cert=$OPTARG
    ;;
  n)
    NoSleep=1
    ;;
  C)
    AllowConcatenation=1
    ;;
  S)
    NewSource=$OPTARG
    ;;
  Q)
    NewQueue=$OPTARG
    ;;
  A)
    ARCHIVE=$OPTARG
    ;;
  F)
    NewFeed=$OPTARG
    ;;
  U)
    NewURL=$OPTARG
    ;;
  E)
    NewEnvironment=$OPTARG
    ;;
  s)
    NewSystem=$OPTARG
    ;;
  V)
    NewVersion=$OPTARG
    ;;
  Z)
    NewMySecZone=$OPTARG
    ;;
  0)
    Prefix=$OPTARG
    ;;
  1)
    Suffix=$OPTARG
    ;;
  d)
    NoDelay=$OPTARG
    ;;
  l)
    LckTemplate=$OPTARG
    ;;
  \?)
    echo "$0: Invalid option -$OPTARG"
    echo $Usage
    exit 1
    ;;
 esac
done

if [ "${LckTemplate}" != $Arg0 ]; then
  LCK_FILE=/tmp/$LckTemplate.lck
fi

if [ -n "${cacert}" ]; then
  if [ ! -f ${cacert} ]; then
    echo "$0: cacert file not found - ${cacert}"
    echo $Usage
    exit 1
  fi
  if [ ! -n "${cert}" ]; then
    echo "$0: cacert option also requires cert (-p) option"
    echo $Usage
    exit 1
  fi
fi

if [ -n "${cert}" ]; then
  if [ ! -f ${cert} ]; then
    echo "$0: cert file not found - ${cert}"
    echo $Usage
    exit 1
  fi
  if [ ! -n "${cacert}" ]; then
    echo "$0: cert option also requires cacert (-c) option"
    echo $Usage
    exit 1
  fi
fi


# SYSTEM            - Name of System
SYSTEM="My Stroom Capability"

if [ -n "${NewSystem}" ]; then
  SYSTEM="${NewSystem}"
fi

# ENVIRONMENT       - Application environment
# Can be  Production, QualityAssurance or Development
ENVIRONMENT="Production"

if [ -n "${NewEnvironment}" ]; then
  ENVIRONMENT="${NewEnvironment}"
fi

# URL               - URL for posting gzip'd audit log files
#
# This should NOT change without consultation with Audit Authority
URL=https://stroomp00.strmdev00.org/stroom/datafeed

if [ -n "${NewURL}" ]; then
  URL="${NewURL}"
fi

# mySecZone     - Security zone if pertinant
#
# We set this typically externally to the base script script source
mySecZone="none"

if [ -n "${NewMySecZone}" ]; then
  mySecZone="${NewMySecZone}"
fi

# VERSION           - The version of the log source
#
# This is to allow one to distinguish between different versions of the capability
# generating logs. If you have strong version control on the logging element of
# your application, you can use your release of the installed utility version.
VERSION="V1.0"

if [ -n "${NewVersion}" ]; then
  VERSION="${NewVersion}"
fi


# FEED_NAME         - Name of Stroom feed (asssigned by Audit Authority)
#
FEED_NAME="SomeApplication-V3.0-EVENTS"

if [ -n "${NewFeed}" ]; then
  FEED_NAME="${NewFeed}"
fi

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
STROOM_LOG_SOURCE=/var/log/someapplication
STROOM_LOG_QUEUED=/var/log/someapplication/queue

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

# gain_iana_timezone()
# Args:
#   null
#
# Gain the host's Canonical timezone
# The algorithm in general is
#   if /etc/timezone then
#     This is a ubuntu scenario
#     cat /etc/timezone
#   elif /etc/localtime is a symbolic link and /usr/share/zoneinfo exists
#     # This is a RHEL/BSD scenario. Get the filename in the database directory
#     readlink /etc/localtime | sed -e 's@.*share/zoneinfo/@@'
#   elif /etc/localtime is a file and /usr/share/zoneinfo exists
#     # This is also a RHEL/BSD scenario. Get the filename in the database directory by brute force comparison
#     find /usr/share/zoneinfo -type f ! -name 'posixrules' -exec cmp -s {} /etc/localtime \; -print | sed -e 's@.*/zoneinfo/@@' | head -n1
#   elif /etc/TIMEZONE exists
#     # This is for Solaris for completeness. Get the TZ value. May need to delete double quotes
#     grep 'TZ=' /etc/TIMEZONE | cut -d= -f2- | sed -e 's/"//g'
#   else
#     nothing
#
gain_iana_timezone()
{
  if [ -f /etc/timezone ]; then
    # Ubuntu based
    cat /etc/timezone
  elif [ -h /etc/localtime -a -d /usr/share/zoneinfo ]; then
    # RHEL/BSD based
    readlink /etc/localtime | sed -e 's@.*share/zoneinfo/@@'
  elif [ -f /etc/localtime -a -d /usr/share/zoneinfo ]; then
    # Older RHEL based
    find /usr/share/zoneinfo -type f ! -name 'posixrules' -exec cmp -s {} /etc/localtime \; -print | sed -e 's@.*/zoneinfo/@@' | head -n1
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
        h0=`host $h 2>&1 | gawk '{print $NF }'`
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
    # Redirect facter's stderr as we may not be root
    myMeta=`facter 2>/dev/null | awk '{
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

  # Local Canonical Timezone
  ctz=`gain_iana_timezone`
  if [ -n "${ltz}" ]; then
      hostArgs="${hostArgs} -H MyCanonicalTZ:${ctz}"
  fi

  # Do the transfer.

  # If we have specified a certificate and root certificate, set up the appropriate arguments
  # Note that we have tested for the existance of both cert and cacert in earlier argument processing
  if [ -n "${cert}" ]; then
    curlCertArgs="--cert ${cert} --cacert ${cacert}"
  else
    curlCertArgs="-k"
  fi

  if [ -n "${mySecZone}" -a "${mySecZone}" != "none" ]; then
    RESPONSE_HTTP=`curl ${curlCertArgs} --connect-timeout ${C_TMO} --max-time ${M_TMO} --data-binary @${logFile} ${URL} \
-H "Feed:${FEED_NAME}" -H "System:${SYSTEM}" -H "Environment:${ENVIRONMENT}" -H "Version:${VERSION}" \
-H "MyHost:\"${myHost%"${myHost##*[![:space:]]}"}\"" \
-H "MyIPaddress:\"${myIPaddress%"${myIPaddress##*[![:space:]]}"}\"" \
-H "MySecurityDomain:\"${mySecZone%"${mySecZone##*[![:space:]]}"}\"" \
${hostArgs} \
-H "Compression:GZIP" --write-out "RESPONSE_CODE=%{http_code}" 2>&1`
  else
    RESPONSE_HTTP=`curl ${curlCertArgs} --connect-timeout ${C_TMO} --max-time ${M_TMO} --data-binary @${logFile} ${URL} \
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

# Check delay
if [[ $NoDelay != *[[:digit:]]* ]]; then
  logmsg "Delay Seconds (-d) is not an integer - ${NoDelay}"
  exit 1
fi

# Get a lock
stroom_get_lock

if [ -n "${NewSource}" ]; then
  STROOM_LOG_SOURCE=${NewSource}
fi
if [ -n "${NewQueue}" ]; then
  STROOM_LOG_QUEUED=${NewQueue}
fi

# If there is no source then exit with an error
if [ ! -d ${STROOM_LOG_SOURCE} ]; then
    logmsg "No source directory  - ${STROOM_LOG_SOURCE}"
    stroom_rm_lock # Release the lock
    exit 1
fi

# Create queue directory if need be
if [ ! -d ${STROOM_LOG_QUEUED} ]; then
    mkdir -p ${STROOM_LOG_QUEUED};
    if [ $? -ne 0 ]; then
        logmsg "Cannot create queue directory - ${STROOM_LOG_QUEUED}"
        stroom_rm_lock # Release the lock
        exit 1
    fi
fi

# If provided, then the archive directory must exist and be writable
if [ "${ARCHIVE}x" != "x" ]; then
    if [ -d ${ARCHIVE} ]; then
        cp /dev/null ${ARCHIVE}/test_fn.$$ > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            logmsg "Cannot write to archive directory - ${ARCHIVE}"
            stroom_rm_lock # Release the lock
            exit 1
        fi
        rm -f ${ARCHIVE}/test_fn.$$
    else
        logmsg "No archive directory - ${ARCHIVE}"
        stroom_rm_lock # Release the lock
        exit 1
    fi
fi

# We may need to sleep
if [ ${NoSleep} -eq 0 ]; then
  logmsg "Will sleep for ${SLEEP}s to help balance network traffic"
  sleep ${SLEEP}
fi

# We now collect the logs from the source and move them
# into our queueing directory

# We expect that the application has rolled over it's log files into $STROOM_LOG_SOURCE with the nomenclature
# ${Prefix}*${Suffix}

uTag=`date +%s`
cd ${STROOM_LOG_SOURCE}
# First see if we have log files to collect
l=`ls ${Prefix}*${Suffix} 2>/dev/null`
if [ ! -z "${l}" ]; then
  for f in ${l}; do
    if [ -s $f ]; then
      if [ ${AllowConcatenation} -eq 1 ]; then
        # Concatenate onto primary queue file
        cat ${f} >> ${STROOM_LOG_QUEUED}/${uTag}._StroomPost_events && rm -f ${f}
      else
	cp ${f} ${STROOM_LOG_QUEUED}/${uTag}.`basename ${f}`._StroomPost_events && rm -f ${f}
      fi
    else 
      # Remove empty files
      rm -f ${f}
    fi
  done
fi

# Go to the queue directory and post
cd ${STROOM_LOG_QUEUED}
# Gzip any non-gziped files but with our tempate of <epoch><something>._StroomPost_events
l=`find . -type f -regextype sed -regex "./[0-9]\+.*._StroomPost_events$"`
if [ ! -z "$l" ]; then
  echo $l | xargs gzip --force
fi

_i=0
for f in `find . -type f -regextype sed -regex "./[0-9]\+.*._StroomPost_events.gz$"`; do

  if [ -s ${f} ]; then
    # Only sleep before subsequent files, this way we exit quickly if there is just one file
    if [ $_i -gt 0 ]  && [ $NoDelay -ne 0 ]; then
        sleep $NoDelay
    fi
    # Archive the file
    if [ "${ARCHIVE}x" != "x" ]; then
        # This bit is future proofing the script in case we have a tree of source files eventually
        b=`dirname ${f}`
        if [ ! -d ${ARCHIVE}/$b ]; then
            mkdir -p ${ARCHIVE}/$b
            if [ $? -ne 0 ]; then
                logmsg "Cannot create archive subdirectory - ${ARCHIVE}/$b"
                stroom_rm_lock # Release the lock
                exit 1
            fi
        fi
        cp ${f} ${ARCHIVE}
        if [ $? -ne 0 ]; then
            logmsg "Cannot copy ${f} to archive subdirectory - ${ARCHIVE}/$b"
            stroom_rm_lock # Release the lock
            exit 1
        fi
    fi

    export ProcessTime=0
    send_to_stroom ${f}
    ((_i++))
  else
    rm -f ${f}
 fi
done

clean_store ${STROOM_LOG_QUEUED} ${FAILED_RETENTION} ${FAILED_MAX}
stroom_rm_lock
exit 0
