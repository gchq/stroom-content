# Synopsis
The script `httpd_stroom_feeder.sh` is designed to run from a crontab entry that periodically collects and enriches access events from an appropriately configured Apache Httpd service and posts the enriched events to a Stroom audit repository (web service). It is expected that

  - your Apache httpd deployment has been set up to generate BlackBox variant format apache httpd access logs (see later)
  - Stroom has been configured to accept streams of events in the ApacheHttpd-BlackBox-V1.0-EVENTS feed.


# Storage Imposts
  - Deployment size of approx 32K
  - Temporary storage of up to 8.00GB for a period of 90 days (given failure of the Stroom Audit System web service) within the configured Apache HTTPD log directory (see later). These values are the default posture, if you need to change this, then edit `httpd_stroom_feeder.sh` and change one or both of the **FAILED_RETENTION** and **FAILED_MAX**  environment variables

# Prerequisites
  - Apache HTTPD configured appropriately (see later)
  - requires the bind-utils, coreutils, curl, net-tools, gzip and sed packages.

# Capability Workflow
The workflow is such that, every 10 minutes cron starts a script which
  - delays randomly between 7 and 580 seconds before collecting audit data in order to balance network load. One does not want many Linux systems 'pulsing' the network every 10 minutes.
  - captures all rolled over httpd access logs and runs the Apache Httpd _logresolve_ utility to enrich the logs by converting the duplicate client ip address at the start of every line into a fully qualified domain name or hostname.
  - the resultant log files are gzip'd within the queuing directory
  - all files in the queue directory are posted to the Stroom web service. On failure the files are left in place and will be posted on the next iteration when the web service is available. A protection mechanisms that places a size and time limit on the amount of files stored is applied to remove (age-off) the oldest files.

# Apache Configuration
The main Apache HTTPD configuration file, `/etc/httpd/conf/httpd.conf`, normally holds the format definitions for the various Apache HTTPD log formats.  The normal, at time of writing (Apache httpd V2.4), are present in this file as
```
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    LogFormat "%{Referer}i -> %U" referer
    LogFormat "%{User-agent}i" agent
```

The default access logging posture is to log using the standard 'combined' format via the directive
```
    CustomLog logs/access_log combined
```

in the primary `/etc/httpd/conf/httpd.conf` configuration file, and
```
    CustomLog logs/ssl_request_log \
       "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
```
in `/etc/httpd/conf.d/ssl.conf` SSL related Httpd configuration file.

This standard configuration results in standard access and ssl access logs being collected in /var/log/httpd/access_log and /var/log/httpd/ssl_request_log. These files rotation are managed by an Apache logrotate configuration (also standard).

To gain better information from the Apache httpd service we use the so-called BlackBox log format which gathers more information about a web service transaction. We store the resultant active BlackBox format log files in a different directory to deconflict any pre-configuration log rotation mechanisms. We configure these logs to roll over every 600 seconds.

To achieve this the configuration changes need to be
  - Create both the BlackBox log directory and BlackBox log queuing directory. Note these directories are preset in the `httpd_stroom_feeder.sh` script so if you change them, change the script (see **STROOM_LOG_QUEUED** and **STROOM_LOG_SOURCE** variables). If you change deployment of Apache httpd to run as a different user to the default, then ensure these directories are owned by the different user.

```bash
    mkdir /var/log/httpd/httpdCurrent /var/log/httpd/httpdQueue
    chcon -R --reference /var/log/httpd /var/log/httpd/httpdCurrent /var/log/httpd/httpdQueue
```
  - Change the `/etc/httpd/conf/httpd.conf` configuration file to
    - Add the new BlackBox log formats (see below)
    - If you plan to gain http logs (a'la access_log) then either add a new CustomLog directive to generate them using inbuilt file rotation, or not
    - Optionally comment out the existing access_log CustomLog
    The above would look like, assuming we are **NOT** continue to collect `combined` format logs in `logs/access_log` and we are going to generate `blackboxUser` logs in `/var/log/httpd/httpdCurrent/access_log`

```
    # Add new BlackBox log format directives.
    # We use two different format pairs depending on the presence of the logio module. The different pairs are based on the collection
    # from either the access_log (ie use blackboxUser) or the ssl_request_log (ie use blackboxSSLUser as we expect that we can collect the user name
    # from the SSL_CLIENT_S_DN variable. This MAY need to change.
    <IfModule logio_module>
      LogFormat "%a %a/%{REMOTE_PORT}e %X [%{%FT%T}t.%{msec_frac}t %{%z}t] %l \"%u\" \"%r\" %s/%>s %D %I/%O/%B \"%{Referer}i\" \"%{User-Agent}i\" %V/%p \"%q\"" blackboxUser
      LogFormat "%a %a/%{REMOTE_PORT}e %X [%{%FT%T}t.%{msec_frac}t %{%z}t] %l \"%{SSL_CLIENT_S_DN}x\" \"%r\" %s/%>s %D %I/%O/%B \"%{Referer}i\" \"%{User-Agent}i\" %V/%p \"%q\"" blackboxSSLUser
    </IfModule>
    # Add new log formats if the logio module is not present
    <IfModule !logio_module>
      LogFormat "%a %a/%{REMOTE_PORT}e %X [%{%FT%T}t.%{msec_frac}t %{%z}t] %l \"%u\" \"%r\" %s/%>s %D -/-/%B \"%{Referer}i\" \"%{User-Agent}i\" %V/%p \"%q\"" blackboxUser
      LogFormat "%a %a/%{REMOTE_PORT}e %X [%{%FT%T}t.%{msec_frac}t %{%z}t] %l \"%{SSL_CLIENT_S_DN}x\" \"%r\" %s/%>s %D -/-/%B \"%{Referer}i\" \"%{User-Agent}i\" %V/%p \"%q\"" blackboxSSLUser
    </IfModule>

    # Optionally comment out the access_log CustomLog directive as per
    #CustomLog "logs/access_log" common

    # Add in the new access_log Black Box directive
    CustomLog "|/usr/sbin/rotatelogs /var/log/httpd/httpdCurrent/access_log 600" blackboxUser
```

  - Change the `/etc/httpd/conf.d/ssl.conf` configuration file to
    - It is assumed you have added the LogFormat directive's into `/etc/httpd/conf/httpd.conf`
    - If you plan to gain http logs (a'la ssl_request_log) then add a new CustomLog directive to generate them using inbuilt file rotation, or not
    - Optionally comment out the existing access_log CustomLog

    The above would look like, assuming we are **NOT** continue to collect custom format logs in `logs/ssl_request_log` and we are going to collect `blackboxSSLUser` format log in `/var/log/httpd/httpdCurrent/ssl_request_log`
```
    # Optionally comment out the access_log CustomLog directive as per
    # CustomLog logs/ssl_request_log \
    #     "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"

    # Add in the new access_log Black Box directive
    CustomLog "|/usr/sbin/rotatelogs /var/log/httpd/httpdCurrent/ssl_request_log 600" blackboxSSLUser
```
  - Restart httpd service


# Manual Deployment

You need to configure your Apache Httpd service as per above and after a restart, validate that the access log(s) are now being formed in the files
`/var/log/httpd/httpdCurrent/<accesslogname>.<epoch>` where `<accesslogname>` is, assuming the above configuration, `access_log` and/or `ssl_request_log` and `<epoch>` is the system time at which the log is nominally created.

Ensuring you have met the prerequisites (especially bind-utils) deploy the script `httpd_stroom_feeder.sh`. If Apache Httpd does not run as root (the default), then ensure the apache users can access the script. A location might be __/usr/audit/httpd__. 

The following assumes the script has been deployed in __/usr/audit/httpd__ with ownerships and permissions set correctly.

You will need to modify the file `/usr/audit/httpd/httpd_stroom_feeder.sh` and change at least one variable and ensure other variables are appropriately set. Explicit information about environment variable use can be found in the script itself.

You must change the **URL** variable to have it direct processed log files to your Stroom instance. By default it posts to `https://stroomp00.strmdev00.org/stroom/datafeed` as per
```
  URL=https://stroomp00.strmdev00.org/stroom/datafeed
```

You may also want to change the **SYSTEM** and **mySecZone** variables as well. Further check that **STROOM_LOG_SOURCE** and **STROOM_LOG_QUEUED** are
using the correct directories set up in the Apache Httpd configuration.

If you want to maintain a set of your Black Box logs locally, or instead of the standard Httpd access logs, then ensure the **PrimaryLogA** and **PrimaryLogB** variables are set.

If you want to change the periodicity of execution ensure the **MAX_SLEEP** variable is LOWER than the crontab periodicity. The default is 10 minutes,
so your crontab entry should look like
```
  */10 * * * * /usr/audit/httpd/httpd_stroom_feeder.sh >> /var/log/stroom_httpd_post.log 2>&1
```
