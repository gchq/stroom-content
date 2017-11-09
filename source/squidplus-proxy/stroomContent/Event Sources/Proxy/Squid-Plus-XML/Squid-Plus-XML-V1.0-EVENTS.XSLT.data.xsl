<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns="event-logging:3" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

  <!-- 
  This Translation is for logs from a Squid Proxy using the SquidPlus log format (see below)
  together with a supporting script that enriches the original event and converts the output format into XML.
  
  It is recommended to enable query capture in urls. To do this, in your squid.conf file add
  
  # Keep query terms in the Request URL
  strip_query_terms off
  
  Squid Plus Format:
  The SquidPlus logging format is designed to gain additional information about the proxy transaction.
  
  The format is defined below.
  
  logformat squidplus %ts.%03tu %tr %>a/%>p %<a/%<p %<la/%<lp %>la/%>lp %Ss/%>Hs/%<Hs %<st/%<sh %>st/%>sh %mt %rm "%ru" "%un" %Sh "%>h" "%<h"
  
  %ts.%03tu Seconds since epoch '.' subsecond time (milliseconds)
  %tr Response time (milliseconds)
  %>a/%>p Client source IP address '/' Client source port
  %<a/%<p Server IP address of the last server or peer connection '/' Server port number of the last server or peer connection
  %<la/%<lp Local IP address of the last server or peer connection '/' Local port number of the last server or peer connection
  %>la/%>lp Local IP address the client connected to '/' Local port number the client connected to
  %Ss/%>Hs/%<Hs Squid request status (TCP_MISS etc) '/' HTTP status code sent to the client '/' HTTP status code received from the next hop
  %<st/%<sh Total size of reply sent to client (after adaptation) '/' Size of reply headers sent to client (after adaptation)
  %>st/%>sh Total size of request received from client. '/' Size of request headers received from client
  %mt MIME content type
  %rm Request method (GET/POST etc)
  "%ru" '"' Request URL from client (historic, filtered for logging) '"'
  "%un" '"' User name (any available) '"'
  %Sh Squid hierarchy status (DEFAULT_PARENT etc)
  "%>h" '"' Original received request header. '"'
  "%<h" '"' Reply header. '"'
  
  It should be noted that we do not use the '>A', '<A' directives in the above to gain appropriate FQDN's as this risks performance of the Squid Proxy.
  Rather we gain this information by enriching the log when preparing the logs for transmission to the audit service. To achieve this,
  a perl script parses the logs and attempts to resolve each given IP address into a FQDN and adds the result to the log (resolved or not). It is acknowledged,
  that in a highly volatile environment when host FQDN's change quick, we have a risk that by the time we attempt to resolve IP addresses to FQDN's they may have
  changed. This risk is accepted given the consequence of reducing the performance of the proxy itself.
  
  As well as resolving host FQDNs, in order to reduce the compute requirements of the audit service, the logs are formatted into a simple XML form.
  
  The XML 'schema' is
  root: <Evts>
  event: <Evt>
  event subelments:
  dtg - Seconds since epoch '.' subsecond time (milliseconds) (source %ts.%03tu)
  rTime - Response time (milliseconds) (source %tr)
  cIP - Client source IP address (source %>a)
  cHost - Client Source FQDN (enrichment)
  cPort - Client source port number (source %>p)
  sIP - Server IP address of the last server or peer connection (source %<a)
  sHost - Server FQDN of the last server or peer connection (enrichment)
  sPort - Server port number of the last server or peer connection (source %<p)
  lcIP - Local IP address the client connected to (source %>la)
  lcHost - Local IP address the client connected to (source enrichment)
  lcPort - Local port number the client connected to (source %>lp)
  lsIP - Server IP address of the last server or peer connection (source %<la)
  lsHost - Server FQDN of the last server or peer connection (enrichment)
  lsPort - Server port number of the last server or peer connection (source %<lp)
  rStatus - Squid request status (TCP_MISS etc) (source %Ss)
  tCliStatus - HTTP status code sent to the client (source %>Hs)
  nHopStatus - HTTP status code received from the next hop (source %<Hs)
  SzAllTo - Total size in bytes of reply sent to client (after adaptation) (source %<st)
  SzHdrsTo - Size in bytes of reply headers sent to client (after adaptation) (source %<sh)
  SzAllFrom - Total size in bytes of request received from client (source %>st)
  SzHdrsFrom - Size in bytes of request headers received from client (source %>sh)
  mime - MIME content type (source %mt)
  rMethod - Request Method (GET, POST, etc) (source %rm)
  rURL - Request URL from client historic, filtered for logging (source %ru)
  user - User name (any available) (source %un)
  hierarch - Squid hierarchy Status (DEFAULT_PARENT, etc) (source %Sh) 
  recHdr - Original received request header (source %>h)
  rplHdr - Reply header (source %<h)
  
  -->

  <!-- Ingest the Evts tree -->
  <xsl:template match="Evts">
    <Events xsi:schemaLocation="event-logging:3 file://event-logging-v3.1.1.xsd" Version="3.1.1">
      <xsl:apply-templates />
    </Events>
  </xsl:template>

  <!-- Main record template for single Evt event -->
  <xsl:template match="Evt">
    <Event>
      <xsl:call-template name="event_time" />
      <xsl:call-template name="event_source" />
      <xsl:call-template name="event_detail" />
    </Event>
  </xsl:template>

  <!-- Time -->
  <xsl:template name="event_time">
    <EventTime>
      <TimeCreated>
        <xsl:value-of select="stroom:format-date(translate(dtg,'.',''))" />

        <!-- strip the period before msecs -->
      </TimeCreated>
    </EventTime>
  </xsl:template>

  <!-- Template for event source-->
  <xsl:template name="event_source">

    <!--
    We extract some situational awareness information that the posting script includes when posting the event data 
    -->
    <xsl:variable name="_myhost" select="translate(stroom:feed-attribute('MyHost'),'&quot;', '')" />
    <xsl:variable name="_myip" select="translate(stroom:feed-attribute('MyIPaddress'),'&quot;', '')" />
    <xsl:variable name="_mymeta" select="translate(stroom:feed-attribute('MyMeta'),'&quot;', '')" />
    <xsl:variable name="_myns" select="translate(stroom:feed-attribute('MyNameServer'),'&quot;', '')" />
    <xsl:variable name="_deviceHostName">

      <!-- For the device host name we choose, in order, contents of
      - MyHost header variable in post
      - FQDN portion of MyMeta header variable in post
      - @host attribute on the event element
      - the 'RemoteHost' attribute that Stroom's proxy evaluated
      -->
      <xsl:choose>
        <xsl:when test="string-length($_myhost) > 0 and contains($_myhost, ' ')">
          <xsl:value-of select="substring-before($_myhost, ' ')" />
        </xsl:when>
        <xsl:when test="string-length($_myhost) > 0">
          <xsl:value-of select="$_myhost" />
        </xsl:when>
        <xsl:when test="string-length($_mymeta) > 0">
          <xsl:value-of select="substring-before(substring-after($_mymeta,'FQDN:'),'\')" />
        </xsl:when>
        <xsl:when test="@host">
          <xsl:value-of select="@host" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="stroom:feed-attribute('RemoteHost')" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="_deviceIP">

      <!-- For the device ip address we choose, in order, contents of
      - MyHost header variable in post
      - ipaddress portion of MyMeta header variable in post
      - the 'RemoteAddress' attribute that Stroom's proxy evaluated
      -->
      <xsl:choose>
        <xsl:when test="string-length($_myip) > 0 and contains($_myip, ' ')">
          <xsl:value-of select="substring-before($_myip, ' ')" />
        </xsl:when>
        <xsl:when test="string-length($_myip) > 0 and contains($_myip, '%')">
          <xsl:value-of select="substring-before($_myip, '%')" />
        </xsl:when>
        <xsl:when test="string-length($_myip) > 0">
          <xsl:value-of select="$_myip" />
        </xsl:when>
        <xsl:when test="string-length($_mymeta) > 0">
          <xsl:value-of select="substring-before(substring-after($_mymeta,'ipaddress:'),'\')" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="stroom:feed-attribute('RemoteAddress')" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Form the EventSource node -->
    <EventSource>
      <System>
        <Name>
          <xsl:value-of select="stroom:feed-attribute('System')" />
        </Name>
        <Environment>
          <xsl:value-of select="stroom:feed-attribute('Environment')" />
        </Environment>
      </System>
      <Generator>
        <xsl:choose>
          <xsl:when test="stroom:feed-attribute('Version')">
            <xsl:value-of select="stroom:feed-attribute('Version')" />
          </xsl:when>
          <xsl:otherwise>Squid</xsl:otherwise>
        </xsl:choose>
      </Generator>
      <xsl:if test="string-length($_deviceHostName) != 0 or string-length($_deviceIP)!=0">
        <Device>
          <xsl:if test="string-length($_deviceHostName) != 0 ">
            <HostName>
              <xsl:value-of select="$_deviceHostName" />
            </HostName>
          </xsl:if>
          <xsl:if test="string-length($_deviceIP) !=0">
            <IPAddress>
              <xsl:value-of select="$_deviceIP" />
            </IPAddress>
          </xsl:if>
          <xsl:if test="stroom:feed-attribute('MyTZ')">
            <Location>
              <TimeZone>
                <xsl:value-of select="stroom:feed-attribute('MyTZ')" />
              </TimeZone>
            </Location>
          </xsl:if>
          <xsl:if test="string-length($_myns) > 0">
            <Data Name="NameServer" Value="{$_myns}" />
          </xsl:if>
        </Device>
      </xsl:if>

      <!-- -->
      <Client>
        <HostName>
          <xsl:value-of select="cHost" />
        </HostName>
        <xsl:if test="cIP != '-'">
          <IPAddress>
            <xsl:value-of select="cIP" />
          </IPAddress>
        </xsl:if>

        <!-- Remote Port Number -->
        <xsl:if test="cPort !='-'">
          <Port>
            <xsl:value-of select="cPort" />
          </Port>
        </xsl:if>
      </Client>

      <!-- -->
      <Server>
        <HostName>
          <xsl:value-of select="sHost" />
        </HostName>
        <xsl:if test="sIP != '-'">
          <IPAddress>
            <xsl:value-of select="sIP" />
          </IPAddress>
        </xsl:if>

        <!-- Remote Port Number -->
        <xsl:if test="sPort !='-'">
          <Port>
            <xsl:value-of select="sPort" />
          </Port>
        </xsl:if>
      </Server>

      <!-- -->
      <xsl:if test="user !='-'">
        <User>
          <Id>
            <xsl:value-of select="user" />
          </Id>
        </User>
      </xsl:if>
      <Data Name="Feed">
        <xsl:attribute name="Value" select="stroom:feed-name()" />
      </Data>
    </EventSource>
  </xsl:template>

  <!-- Event detail -->
  <xsl:template name="event_detail">
    <EventDetail>

      <!--
      We model Proxy events as either Recieve or Send events depending on the method.
      
      We make use of the Receive/Send subelements Source/Destination to map the Client/Destination Squid values
      and the Payload sub-element to map the URL and other details of the activity
      -->

      <!-- 
      We consider a query to be at least ONE character and rely on the URL query indicator ? 
      -->
      <xsl:choose>
        <xsl:when test="matches(rURL, '.+?.+')">
          <TypeId>ProxyConnection-Query</TypeId>
        </xsl:when>
        <xsl:otherwise>
          <TypeId>ProxyConnection</TypeId>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="matches(rMethod, 'GET|OPTIONS|HEAD')">
          <Description>Receipt of information from a Resource via Proxy</Description>
          <Receive>
            <xsl:call-template name="setupParticipants" />
            <Payload>
              <xsl:call-template name="setPayload" />
            </Payload>
            <xsl:call-template name="setOutcome" />
          </Receive>
        </xsl:when>
        <xsl:otherwise>
          <Description>Transmission of information to a Resource via Proxy</Description>
          <Send>
            <xsl:call-template name="setupParticipants" />
            <Payload>
              <xsl:call-template name="setPayload" />
            </Payload>
            <xsl:call-template name="setOutcome" />
          </Send>
        </xsl:otherwise>
      </xsl:choose>
    </EventDetail>
  </xsl:template>

  <!-- Establish the Source and Destination nodes -->
  <xsl:template name="setupParticipants">
    <Source>
      <Device>
        <HostName>
          <xsl:value-of select="cHost" />
        </HostName>
        <xsl:if test="cIP != '-'">
          <IPAddress>
            <xsl:value-of select="cIP" />
          </IPAddress>
        </xsl:if>

        <!-- Remote Port Number -->
        <xsl:if test="cPort !='-'">
          <Port>
            <xsl:value-of select="cPort" />
          </Port>
        </xsl:if>
      </Device>
    </Source>
    <Destination>
      <Device>
        <HostName>
          <xsl:value-of select="sHost" />
        </HostName>
        <xsl:if test="sIP != '-'">
          <IPAddress>
            <xsl:value-of select="sIP" />
          </IPAddress>
        </xsl:if>

        <!-- Remote Port Number -->
        <xsl:if test="sPort !='-'">
          <Port>
            <xsl:value-of select="sPort" />
          </Port>
        </xsl:if>
      </Device>
    </Destination>
  </xsl:template>

  <!-- Define the Payload node -->
  <xsl:template name="setPayload">
    <xsl:variable name="query">
      <xsl:if test="matches(rURL, '.+?.+')">
        <xsl:value-of select="substring-after(rURL, '?')" />
      </xsl:if>
    </xsl:variable>
    <xsl:if test="$query != ''">
      <Criteria>
        <DataSources>
          <DataSource>
            <xsl:value-of select="substring-before(rURL, '?')" />
          </DataSource>
        </DataSources>
        <Query>
          <Raw>
            <xsl:value-of select="$query" />
          </Raw>
        </Query>
      </Criteria>
    </xsl:if>
    <Resource>
      <URL>
        <xsl:value-of select="rURL" />
      </URL>
      <xsl:if test="contains(recHdr, 'Referer:')">
        <Referrer>
          <xsl:value-of select="substring-before(substring-after(recHdr, 'Referer: '), '\r')" />
        </Referrer>
      </xsl:if>
      <HTTPMethod>
        <xsl:value-of select="rMethod" />
      </HTTPMethod>
      <xsl:if test="contains(recHdr, 'User-Agent:')">
        <UserAgent>
          <xsl:value-of select="substring-before(substring-after(recHdr, 'User-Agent: '), '\r')" />
        </UserAgent>
      </xsl:if>

      <!-- Inbound activity -->
      <InboundSize>
        <xsl:value-of select="SzAllFrom" />
      </InboundSize>
      <InboundContentSize>
        <xsl:value-of select="format-number(SzAllFrom - SzHdrsFrom, '#')" />
      </InboundContentSize>
      <xsl:if test="recHdr != '-'">
        <InboundHeader>
          <xsl:value-of select="recHdr" />
        </InboundHeader>
      </xsl:if>

      <!-- Outbound activity -->

      <!-- Sometimes squid generates a szAllTo(the Client) of 0 but a header size greater than 0, so we adjust -->
      <xsl:variable name="outbytes">
        <xsl:choose>
          <xsl:when test="SzAllTo > 0">
            <xsl:value-of select="SzAllTo" />
          </xsl:when>
          <xsl:when test="SzAllTo = 0 and SzHdrsTo > 0">
            <xsl:value-of select="SzHdrsTo" />
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <OutboundSize>
        <xsl:value-of select="$outbytes" />
      </OutboundSize>
      <OutboundContentSize>
        <xsl:value-of select="format-number($outbytes - SzHdrsTo, '#')" />
      </OutboundContentSize>
      <xsl:if test="rplHdr != '-'">
        <OutboundHeader>
          <xsl:value-of select="rplHdr" />
        </OutboundHeader>
      </xsl:if>

      <!-- -->
      <RequestTime>
        <xsl:value-of select="rTime" />
      </RequestTime>
      <xsl:if test="rStatus != '-'">
        <ConnectionStatus>
          <xsl:value-of select="rStatus" />
        </ConnectionStatus>
      </xsl:if>
      <InitialResponseCode>
        <xsl:value-of select="nHopStatus" />
      </InitialResponseCode>
      <ResponseCode>
        <xsl:value-of select="tCliStatus" />
      </ResponseCode>
      <xsl:if test="mime != '-'">
        <MimeType>
          <xsl:value-of select="mime" />
        </MimeType>
      </xsl:if>
      <Data Name="ProxyNextClientIP" Value="{lcIP}" />
      <Data Name="ProxyNextClientFQDN" Value="{lcHost}" />
      <Data Name="ProxyNextClientPort" Value="{lcPort}" />
      <Data Name="ProxyNextServerIP" Value="{lsIP}" />
      <Data Name="ProxyNextServerFQDN" Value="{lsHost}" />
      <Data Name="ProxyNextServerPort" Value="{lsPort}" />
      <Data Name="ProxyHierarchy" Value="{hierarch}" />
    </Resource>
  </xsl:template>

  <!-- 
  Set up the Outcome node.
  
  We only set an Outcome for an error state. The absence of an Outcome inferrs success
  -->
  <xsl:template name="setOutcome">
    <xsl:choose>

      <!-- Favour squid specific errors first -->
      <xsl:when test="tCliStatus > 500">
        <Outcome>
          <Success>false</Success>
          <Description>
            <xsl:call-template name="responseCodeDesc">
              <xsl:with-param name="code" select="tCliStatus" />
            </xsl:call-template>
          </Description>
        </Outcome>
      </xsl:when>

      <!-- Now check for 'normal' errors -->
      <xsl:when test="tCliStatus > 400">
        <Outcome>
          <Success>false</Success>
          <Description>
            <xsl:call-template name="responseCodeDesc">
              <xsl:with-param name="code" select="tCliStatus" />
            </xsl:call-template>
          </Description>
        </Outcome>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Response Code map to Descriptions -->
  <xsl:template name="responseCodeDesc">
    <xsl:param name="code" />
    <xsl:choose>

      <!-- Informational -->
      <xsl:when test="$code = 100">Continue</xsl:when>
      <xsl:when test="$code = 101">Switching Protocols</xsl:when>
      <xsl:when test="$code = 102">Processing</xsl:when>

      <!-- Successful Transaction -->
      <xsl:when test="$code = 200">OK</xsl:when>
      <xsl:when test="$code = 201">Created</xsl:when>
      <xsl:when test="$code = 202">Accepted</xsl:when>
      <xsl:when test="$code = 203">Non-Authoritative Information</xsl:when>
      <xsl:when test="$code = 204">No Content</xsl:when>
      <xsl:when test="$code = 205">Reset Content</xsl:when>
      <xsl:when test="$code = 206">Partial Content</xsl:when>
      <xsl:when test="$code = 207">Multi Status</xsl:when>

      <!-- Redirection -->
      <xsl:when test="$code = 300">Multiple Choices</xsl:when>
      <xsl:when test="$code = 301">Moved Permanently</xsl:when>
      <xsl:when test="$code = 302">Moved Temporarily</xsl:when>
      <xsl:when test="$code = 303">See Other</xsl:when>
      <xsl:when test="$code = 304">Not Modified</xsl:when>
      <xsl:when test="$code = 305">Use Proxy</xsl:when>
      <xsl:when test="$code = 307">Temporary Redirect</xsl:when>

      <!-- Client Error -->
      <xsl:when test="$code = 400">Bad Request</xsl:when>
      <xsl:when test="$code = 401">Unauthorized</xsl:when>
      <xsl:when test="$code = 402">Payment Required</xsl:when>
      <xsl:when test="$code = 403">Forbidden</xsl:when>
      <xsl:when test="$code = 404">Not Found</xsl:when>
      <xsl:when test="$code = 405">Method Not Allowed</xsl:when>
      <xsl:when test="$code = 406">Not Acceptable</xsl:when>
      <xsl:when test="$code = 407">Proxy Authentication Required</xsl:when>
      <xsl:when test="$code = 408">Request Timeout</xsl:when>
      <xsl:when test="$code = 409">Conflict</xsl:when>
      <xsl:when test="$code = 410">Gone</xsl:when>
      <xsl:when test="$code = 411">Length Required</xsl:when>
      <xsl:when test="$code = 412">Precondition Failed</xsl:when>
      <xsl:when test="$code = 413">Request Entity Too Large</xsl:when>
      <xsl:when test="$code = 414">Request URI Too Large</xsl:when>
      <xsl:when test="$code = 415">Unsupported Media Type</xsl:when>
      <xsl:when test="$code = 416">Request Range Not Satisfiable</xsl:when>
      <xsl:when test="$code = 417">Expectation Failed</xsl:when>
      <xsl:when test="$code = 422">Unprocessable Entity</xsl:when>
      <xsl:when test="$code = 424">Locked/Failed Dependency</xsl:when>
      <xsl:when test="$code = 433">Unprocessable Entity</xsl:when>

      <!-- Server Error -->
      <xsl:when test="$code = 500">Internal Server Error</xsl:when>
      <xsl:when test="$code = 501">Not Implemented</xsl:when>
      <xsl:when test="$code = 502">Bad Gateway</xsl:when>
      <xsl:when test="$code = 503">Service Unavailable</xsl:when>
      <xsl:when test="$code = 504">Gateway Timeout</xsl:when>
      <xsl:when test="$code = 505">HTTP Version Not Supported</xsl:when>
      <xsl:when test="$code = 507">Insufficient Storage</xsl:when>
      <xsl:when test="$code = 600">Squid: header parsing error</xsl:when>
      <xsl:when test="$code = 601">Squid: header size overflow detected while parsing/roundcube: software configuration error</xsl:when>
      <xsl:when test="$code = 603">roundcube: invalid authorization</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('Uknown Code:', $code)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>