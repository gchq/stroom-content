# Synopsis
The script `generic_stroom_feeder.sh` is designed to run from a crontab entry that periodically collects and posts log files to a Stroom event repository (web service). Once collected,
the original log files are deleted, although the script can optionally archive (to a directory) a copy of each file posted.
The script manages the storage impost of the collected log files in the event of post failures. That is, it will queue the collected log files and age off (delete) the oldest given an aggregated size has been met.

It is assumes you have engaged with the Stroom event repository staff to gain
  - a `feedname` to label the event logs you are sending
  - a `URL` to post the event logs to
  - a recommendation on the `environment type` to use (e.g. 'Production', 'Development', etc)
  - a recommendation on the `system description` generating the audit
  - a recommendation on the `version` of event log system being used
  - a recommendation on the `securityzone` you are running within


# Storage Imposts
  - Deployment size of approx 20K (for the script itself)
  - Temporary storage of up to 8.00GB for a period of 90 days (given failure of the Stroom System web service) within the configured queuing log directory (see later). These values are the default posture, if you need to change this, then edit `generic_stroom_feeder.sh` and change one or both of the **FAILED_RETENTION** and **FAILED_MAX**  environment variables

# Prerequisites
The capability generating the log files with event data can
  - place the the logs files in an identified directory, and
  - ensure the files have a certain nomenclature with a file name `prefix` and `suffix`. If the `prefix` is not consistent, then aspirationally the `suffix` is. For example, the files might have the nomenclature `<sometimestamp>.log` in this case we can identify the `suffix` as `.log`. Others may have the nomenclature of `application_A.<somenumber>.events` and in this case we can identify the `prefix` of `application_A` and the suffix of `.events`.
  - requires the bind-utils, coreutils, curl, net-tools, gzip and sed packages. The bind-utils package is not mandatory, but is preferred.

# Capability Workflow
The workflow is such that, every N minutes (the execution periodicity) cron starts this script which
  - on start up delays for a random period of time before proceeding. This is intended to inject random transmission load across a network of many systems posting event data. It is expected that this script run every 10 minutes. If you change this, then change the variable $MAX_SLEEP below to be 20 or so seconds below the execution periodicity.
  - finds all files in the given `eventsdir` which match the regular expression `logfileprefix`.*`logfixsuffix` and either concatenates the files into a single file (if -C is given) or copies them to the `queuedir` directory. The original file name is incorporated into the file that is queued for posting (<epochtime>.originallogfilename._StroomPost_events). If concatenation is enabled, the original log file names are lost.
  - compresses all files in `queuedir` (if not compressed)
  - attempts to post the compressed files and removes them from the queue directory on successful post. If the post fails, the files are left in place for the next invocation. An optional delay can be inserted between posting files and the posted files can be optionally archived.
  - if the total aggregated files in `queuedir` have a size greater than the variable $FAILED_MAX then the oldest files in `queuedir` are removed until the total size is less than $FAILED_MAX. This is to prevent the queue directory filling it's file system based on size.
  - if the files in `queuedir` become older than $FAILED_RETENTION days, then they are removed. This is to prevent the queue directory filling it's file system based on time of files.

# Options
The following options are available. Note that all option arguments are single arguments, so they should be quoted if there are embedded spaces.

| Option | Default | Description |
| :----- | :------ | :---------- |
| -0 logfileprefix | <null> | specify the log filename prefix to collect and post - used in the regular expression `logfileprefix`.*`logfixsuffix` |
| -1 logfilesuffix | '.log' | specify the log filename suffix to collect and post - used in the regular expression `logfileprefix`.*`logfixsuffix` |
| -A archivedirectory | <null> | normally successfully posted log files are deleted, this option moves the posted files to the given archive directory for use by other systems. The directory must exist. |
| -C | <null> | normally the script posts individual files, this option concatenates all files in `eventsdir` before posting ... ie one aggregated post occurs. The directory must exist. |
| -d secs | 0 | specify the number of seconds to sleep between posting multiple files. The directory must exist. |
| -E environment | Production | specify a capability environment type - usually chosen from `Production`, `QualityAssurance` or `Development` |
| -F feedname | SomeApplication-V3.0-EVENTS | specify the Stroom `feedname` provided by the Stroom event repository staff |
| -l lockFileTemplate | <null> | the script has a fixed log file name to prevent multiple invocations. This option allows the user to uniquely identify the lock file, so that the one script may be invoked multiple times simultaneously |
| -n | <null> | normally a random delay is inserted before running script, this prevents the delay from occurring |
| -Q queuedir | /var/log/someapplication/queue | specify the directory where log files are queued until successfully posted |
| -S eventsdir | /var/log/someapplication | specify the directory where the source log files are |
| -s system | My Stroom Capability | specify the log capability name that provides a high level name for the system logging |
| -U URL | https://stroomp00.strmdev00.org/stroom/datafeed | specify the `URL` event log files are to be posted to |
| -V version | V1.0 | specify a version string for the log source. This is typically the application version, if known |
| -Z securityzone | 'none' | specify an optional system security zone, for example 'EastCoast', 'WestCoast', 'Corporate', 'Operational' |
