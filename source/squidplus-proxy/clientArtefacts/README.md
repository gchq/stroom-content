# Synopsis
The script `squid_stroom_feeder.sh` and it's supporting perl script, `squidplusXML.pl`, is designed to run from a crontab entry that periodically collects and enriches events from an appropriately configured single Squid Proxy service and posts the enriched events to an instance of Stroom. It is expected that

  - your squid deployment has been set up to generate SquidPlus format squid logs (see later)
  - Stroom has been configured to accept streams of events in the Squid-Plus-XML-V1.0-EVENTS feed.

If you need to deploy multiple Squid Proxy services on the one system then you WILL need to modify the `squid_stroom_feeder.sh` and Squid configurations to cater for the multiple instances.
NOTE: Currently the SquidPlus format captures both 'original receive request header' (%>h) and 'reply header' (%<h). There is a risk in poorly secured environment, where authentication requests are serviced in the clear, that credentials may be captured in 'Authorization' header variables.  A Squid-cache bugzilla enhancement request exists to allow users to add a 'header name defeat' concept to the existing optional header field name/value filter mechanism. Reference is http://bugs.squid-cache.org/show_bug.cgi?id=4737


# Storage Imposts
  - Deployment size of approx 40K
  - Temporary storage of up to 8.00GB for a period of 90 days (given failure of web service) within the configured Squid log directory (see later).  These values are the default posture, if you need to change this, then edit `squid_stroom_feeder.sh` and change one or both of the **FAILED_RETENTION** and **FAILED_MAX** environment variables

# Prerequisites
  - Squid configured appropriately (see later)
  - requires the bind-utils, coreutils, curl, net-tools, gzip and sed packages. Also requires both perl and perl(XML::Simple) packages as well (including perl-Socket6, perl-XML-Simple)

# Capability Workflow
The workflow is such that, every 10 minutes cron starts a script which
  - delays randomly between 7 and 580 seconds before collecting audit data in order to balance network load. One doesn't want many Linux systems 'pulsing' the network every 10 minutes.
  - runs the squid command with the -k rotate to roll over the current squid log file
  - runs the supporting perl script `squidplusXML.pl` on all rolled over log files (ie log files of the form 'access.log.N') which parses and enriches the original logs reformatting them as simple XML in a queuing directory
  - the resultant log files are gzip'd within the queuing directory
  - all files in the queue directory are posted to the Stroom web service. On failure the files are left in place and will be posted on the next iteration when the web service is available. A protection mechanisms that places a size and time limit on the amount of files stored is applied to remove (age-off) the oldest files.

# Squid Configuration
The main Squid configuration file, `/etc/squid/squid.conf`, holds the configuration information for Squid Access logging. The default posture is to log using the standard 'squid' format via the directive
```
access_log stdio:/var/log/squid/access.log squid
```
which results in standard squid logs being collected in /var/log/squid/access.log.

To gain better information from the Squid proxy we use the so-called SquidPlus log format which gathers more information about a proxy transaction.  We also save the resultant SquidPlus format logs in a different directory to deconflict any pre-configuration log rotation mechanisms.  So the configuration changes need to be
  - Create the SquidPlus log directory and also a squidplus log queuing directory. Note these directories are preset in the `squid_stroom_feeder.sh` script so if you change them, change the script (see **STROOM_LOG_QUEUED** and **STROOM_LOG_SOURCE** variables). Ensure the directories are writable by the appropriate user (typically squid:squid)

```bash
mkdir /var/log/squid/squidCurrent /var/log/squid/squidlogQueue
chown squid:squid /var/log/squid/squidCurrent /var/log/squid/squidlogQueue
```
  - Change the /etc/squid/squid.conf file to
    - Comment out the existing 'access_log' directive
    - Add a logformat directive to define the SquidPlus format
    - Define a new 'access_log' directive to use the SquidPlus format that saves logs in tge /var/log/squid/squidCurrent directory
    - Allow for log file rotation
    - If the proxy can use user attribution, then if the standard %un element doesn't record the attributed user identify, then use an appropriate directive
    The above would look like

```
# Logging
# access_log stdio:/var/log/squid/access.log squid
logformat squidplus %ts.%03tu %tr %>a/%>p %<a/%<p %<la/%<lp %>la/%>lp %Ss/%>Hs/%<Hs %<st/%<sh %>st/%>sh %mt %rm "%ru" "%un" %Sh "%>h" "%<h"
logfile_rotate 10
access_log stdio:/var/log/squid/squidCurrent/access.log squidplus
```
  - Restart squid service


# Manual Deployment

You need to configure you Squid service as per above and after a restart, validate that the access log is now being formed in the file `/var/log/squid/squidCurrent/access.log`

Ensuring you have met the prerequisites (especially bind-utils and perl(XML::Simple)), you should deploy the scripts `squidplusXML.pl` and `squid_stroom_feeder.sh`. Ensuring the squid user can execute them. A location might be __/usr/audit/squid__.  The following assumes both scripts have been deployed in /usr/audit/squid and ownerships set correctly.

You will need to modify the file `/usr/audit/squid/squid_stroom_feeder.sh` and change at least one variable and ensure other variables are appropriately set

You must change the **URL** variable to have it direct processed log files to your Stroom instance. By default it posts to `https://stroomp00.strmdev00.org/stroom/datafeed` as per
```
URL=https://stroomp00.strmdev00.org/stroom/datafeed
```

You may also want to change the **SYSTEM** and **mySecZone** variables as well. Further check that **STROOM_LOG_SOURCE** and **STROOM_LOG_QUEUED** are using the correct directories set up in the Squid configuration and also that the 'standard' Squid access log location is correct and that the log rotate mechanism will rotate it. We concatenate all our logs into this file, defined by the variable **PrimaryLog**

If you want to change the periodicity of execution ensure the **MAX_SLEEP** variable is LOWER than the crontab periodicity. The default is 10 minutes, so your crontab entry should look like
```
*/10 * * * * /usr/audit/squid/squid_stroom_feeder.sh >> /var/log/squid/stroom_squid_post.log
```

