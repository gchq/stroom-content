#!/usr/bin/perl
#

# Install yum install 'perl(XML::Simple)'

# Perl script to take a specific output of a squid proxy server and enrich
# supplied IP addresses with resolved fully qualified domain names if possible and convert
# the data to a simple XML form.
#
# For the purpose of speed, we don't form a correct XML tree but generate individual nodes
# and print them as they are formed (then free them).
# We wrap the output using a simple root element.
# 
# It is required that the squid proxy format is as per
#
# logformat squidplus %ts.%03tu %tr %>a/%>p %<a/%<p %<la/%<lp %>la/%>lp %Ss/%>Hs/%<Hs %<st/%<sh %>st/%>sh %mt %rm "%ru" "%un" %Sh "%>h" "%<h"
#
# %ts.%03tu	Seconds since epoch '.' subsecond time (milliseconds)
# %tr		Response time (milliseconds)
# %>a/%>p	Client source IP address '/' Client source port
# %<a/%<p	Server IP address of the last server or peer connection '/' Server port number of the last server or peer connection
# %<la/%<lp	Local IP address of the last server or peer connection '/' Local port number of the last server or peer connection
# %>la/%>lp	Local IP address the client connected to '/' Local port number the client connected to
#
# %Ss/%>Hs/%<Hs	Squid request status (TCP_MISS etc) '/' HTTP status code sent to the client '/' HTTP status code received from the next hop
# %<st/%<sh	Total size of reply sent to client (after adaptation) '/' Size of reply headers sent to client (after adaptation)
# %>st/%>sh	Total size of request received from client. '/' Size of request headers received from client
# %mt		MIME content type
# %rm		Request method (GET/POST etc)
# "%ru"		'"' Request URL from client (historic, filtered for logging) '"'
# "%un"		'"' User name (any available) '"'
# %Sh		Squid hierarchy status (DEFAULT_PARENT etc)
# "%>h"		'"' Original received request header. '"'
# "%<h"		'"' Reply header. '"'
#

# Externals
#
use strict;
use warnings;
use Unicode::Normalize;
use utf8;
use Socket;
use Socket6;
use XML::Simple qw(XMLout);

# Globals
my ($dtg, $responseTimeMilliSeconds, $clientIP, $clientFQDN, $clientPnum,
    $serverIP, $serverFQDN, $serverPnum,
    $requestStatus, $StatusToClient, $StatusNextHop,
    $szAllToClient, $szHdrsToClient,
    $szAllFromClient, $szHdrsFromClient,
    $requestMethod, $requestURL,
    $user,
    $hierarchy,
    $receivedHdr,
    $replyHdr,
    $mimeContent,
    $lclientIP, $lclientFQDN, $lclientPnum,
    $lserverIP, $lserverFQDN, $lserverPnum);
my $x0;

my %ip_hash;

# Routines

# Timeout for IP address to FQDN resolution
my $TIMEOUT  = 10;
$SIG{'ALRM'} = sub { die "alarmed"; };

# Perform a time restricted hostname lookup but also form a cache as you do
sub nslookup {
  # get the IP as an arg
  my $ip = shift;
  my $hostname = undef;

  unless (exists $ip_hash{$ip}) {
     # do the hostname lookup inside an eval. The eval will use the
     # already configured SIGnal handler and drop out of the {} block
     # regardless of whether the alarm occured or not.
     eval {
       alarm($TIMEOUT);
       my $addr = inet_pton(AF_INET, $ip); # Assune IPV4
       if (defined $addr) {
         $hostname = gethostbyaddr($addr, AF_INET);
       } else {
         $addr = inet_pton(AF_INET6, $ip);
         $hostname = gethostbyaddr($addr, AF_INET6);
       }
       alarm(0);
     };
     if ($@ =~ /alarm/) {
       # useful for debugging perhaps..
       print STDERR "alarming, isn't it? ($ip)\n";
     }
     $ip_hash{$ip} = defined($hostname) ? $hostname : $ip;
   }
   return $ip_hash{$ip};
}

# Seed certain IP's in the IP to hostname cache
#
$ip_hash{'-'} = "-";

# Main


printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
printf "<Evts>\n";

while (<>) {

  chomp;
  my $line = $_;

  # Sometimes the last two header variables are just too large and squid
  # just prints what's in it's buffers. To get around this we capture
  # everything up to the hierarchy in a well defined regex but then
  # capture the last two variables together then attempt to split them
  if (($dtg, $responseTimeMilliSeconds,
    $clientIP, $clientPnum,
    $serverIP, $serverPnum,
    $lclientIP, $lclientPnum,
    $lserverIP, $lserverPnum,
    $requestStatus, $StatusToClient, $StatusNextHop,
    $szAllToClient, $szHdrsToClient,
    $szAllFromClient, $szHdrsFromClient,
    $mimeContent,
    $requestMethod, $requestURL,
    $user,
    $hierarchy,
    $x0
  ) = ($line =~ m/
    ^(\d+\.\d+)\s
    (\d+)\s
    ([^\/]+)\/([^\s]+)\s
    ([^\/]+)\/([^\s]+)\s
    ([^\/]+)\/([^\s]+)\s
    ([^\/]+)\/([^\s]+)\s
    ([^\/]+)\/([^\/]+)\/([^\s]+)\s
    (\d+)\/(\d+)\s
    (\d+)\/(\d+)\s
    (\S+)\s
    ([^\s]+)\s
    "([^"]+)"\s
    "([^"]+)"\s
    (\S+)\s
    (.*)
    $
  /x
  ))
  {

    # Deal with non printing chars (control) in likely input locations
    # Yes. Squid has a bug on requestMethod (%rm) on 400 Bad Request's
    $requestMethod =~ s/([[:cntrl:]])/'&#' . ord($1) . ';'/gse;
    $x0 =~ s/([[:cntrl:]])/'&#' . ord($1) . ';'/gse;
    $requestURL =~ s/([[:cntrl:]])/'&#' . ord($1) . ';'/gse;

    # Now deal with the possible scenarios of
    # "<receivedHdr>" "<replyHdr>"
    # "<receivedHdr>" "<replyHdr>
    # "<receivedHdr>" "
    # "<receivedHdr>
    $replyHdr = "";
    if ($x0 =~ m/"([^"\\]*(\\.[^"\\]*)*)"\s"([^"\\]*(\\.[^"\\]*)*)"$/) {
        $receivedHdr = $1;
        $replyHdr = $3;
    } elsif ($x0 =~ m/"([^"\\]*(\\.[^"\\]*)*)"\s"(.*)$/) {
        $receivedHdr = $1;
        $replyHdr = $3;
    } elsif ($x0 =~ m/"([^"\\]*(\\.[^"\\]*)*)"$/) {
        $receivedHdr = $1;
    } else {
        $receivedHdr = $x0;
    }
    my $event = {
        Evt => [
            {
            dtg       => [ $dtg ],
            rTime 	=> [  $responseTimeMilliSeconds ],
            cIP   	=> [  $clientIP ],
            cHost     => [  nslookup($clientIP) ],
            cPort     => [  $clientPnum ],
            sIP       => [  $serverIP ],
            sHost     => [  nslookup($serverIP) ],
            sPort     => [  $serverPnum ],
            lcIP      => [  $lclientIP ],
            lcHost	=> [  nslookup($lclientIP) ],
            lcPort	=> [  $lclientPnum ],
            lsIP      => [  $lserverIP ],
            lsHost	=> [  nslookup($lserverIP) ],
            lsPort	=> [  $lserverPnum ],
            rStatus	=> [  $requestStatus ],
            tCliStatus	=> [  $StatusToClient ],
            nHopStatus	=> [  $StatusNextHop ],
            SzAllTo	=> [  $szAllToClient ],
            SzHdrsTo	=> [  $szHdrsToClient ],
            SzAllFrom	=> [  $szAllFromClient ],
            SzHdrsFrom	=> [  $szHdrsFromClient ],
            mime      => [  $mimeContent ],
            rMethod	=> [  $requestMethod ],
            rURL      => [  $requestURL ],
            user      => [  $user ],
            hierarch	=> [  $hierarchy ],
            recHdr	=> [  $receivedHdr ],
            rplHdr	=> [  $replyHdr ],
            }
        ]
    };
    print XMLout($event, RootName => undef, NumericEscape => 2);
    undef $event;
  }
}
printf "</Evts>\n";
