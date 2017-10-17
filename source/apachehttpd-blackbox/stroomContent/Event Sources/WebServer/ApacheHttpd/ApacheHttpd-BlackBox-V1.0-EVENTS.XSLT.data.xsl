<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="event-logging:3" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

  <!-- Ingest the records tree -->
  <xsl:template match="records">
    <Events xsi:schemaLocation="event-logging:3 file://event-logging-v3.1.1.xsd" Version="3.1.1">
      <xsl:apply-templates />
    </Events>
  </xsl:template>
  <xsl:template match="record[data[@name = 'url']]">
    <Event>
      <xsl:apply-templates select="." mode="eventTime" />
      <xsl:apply-templates select="." mode="eventSource" />
      <xsl:apply-templates select="." mode="eventDetail" />
    </Event>
  </xsl:template>

  <!-- Template for event time
  We want to cater for either Apache's 
  %t format
  - dd/MMM/yyyy:HH:mm:ss Z
  or
  ISO8601 with microseconds format
  - %{%FT%T}t.%{msec_frac}t %{%z}t
  -->
  <xsl:template match="node()" mode="eventTime">
    <xsl:variable name="date" select="data[@name = 'time']/@value" />
    <xsl:variable name="formattedDate">
      <xsl:choose>
        <xsl:when test="contains($date, '/')">
          <xsl:value-of select="stroom:format-date($date, 'dd/MMM/yyyy:HH:mm:ss Z')" />
        </xsl:when>
        <xsl:when test="contains($date, 'T')">
          <xsl:value-of select="stroom:format-date(replace($date,'T',''), 'yyyy-MM-ddHH:mm:ss.SSS Z')" />
        </xsl:when>
        <xsl:otherwise>

          <!-- Expect a failure -->
          <xsl:value-of select="$date" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <EventTime>
      <TimeCreated>
        <xsl:value-of select="$formattedDate" />
      </TimeCreated>
    </EventTime>
  </xsl:template>

  <!-- Template for event source-->
  <xsl:template match="node()" mode="eventSource">

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

    <!-- We make use of the server name according to the UseCannonicalName setting (%V) -->
    <xsl:variable name="vServer" select="data[@name = 'vserver']/@value" />
    <xsl:variable name="vServerPort" select="data[@name = 'vserverport']/@value" />
    <xsl:variable name="clientHost" select="data[@name = 'resolvedclient']/@value" />
    <xsl:variable name="clientIP" select="data[@name = 'clientip']/@value" />
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
          <xsl:otherwise>Apache HTTPD</xsl:otherwise>
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
        <xsl:if test="string-length($clientHost) > 0">
          <HostName>
            <xsl:value-of select="$clientHost" />
          </HostName>
        </xsl:if>
        <IPAddress>
          <xsl:value-of select="$clientIP" />
        </IPAddress>

        <!-- Remote Port Number -->
        <xsl:if test="data[@name = 'clientport']/@value !='-'">
          <Port>
            <xsl:value-of select="data[@name = 'clientport']/@value" />
          </Port>
        </xsl:if>
      </Client>

      <!-- -->
      <Server>
        <HostName>
          <xsl:value-of select="$vServer" />
        </HostName>

        <!-- Server Port Number -->
        <xsl:if test="$vServerPort !='-'">
          <Port>
            <xsl:value-of select="$vServerPort" />
          </Port>
        </xsl:if>
      </Server>

      <!-- -->
      <xsl:if test="data[@name='user']/@value !='-'">
        <User>
          <Id>
            <xsl:value-of select="data[@name='user']/@value" />
          </Id>
        </User>
      </xsl:if>
      <Data Name="Feed">
        <xsl:attribute name="Value" select="stroom:feed-name()" />
      </Data>
    </EventSource>
  </xsl:template>

  <!-- Template for event detail -->
  <xsl:template match="node()" mode="eventDetail">
    <EventDetail>
      <xsl:variable name="method" select="data[@name = 'url']/data[@name = 'httpMethod']/@value" />

      <!--
      We model an event as a Recieve, Send or Search depending on the method and existance of content in data[@name='query']
      In the case of Receive or Send we make use of the Receive/Send subelements Source/Destination to map the Client/Destination 
      and the Payload sub-element to map the URL and other details of the activity
      In the case of Search, we place the server and url as the DataSource and Query text as raw and use the
      Results/Resource sub-element to map the URL and other details of the activity
      -->
      <xsl:choose>
        <xsl:when test="string-length(data[@name='query']/@value) > 0">
        <TypeId>SearchWebService</TypeId>
          <Description>Search of Web Service</Description>
          <Search>
            <DataSources>
              <DataSource>
                <xsl:value-of select="data[@name = 'vserver']/@value" />
                <xsl:value-of select="data[@name = 'url']/data[@name = 'url']/@value" />
              </DataSource>
            </DataSources>
            <Query>
              <Raw>
                <xsl:value-of select="data[@name='query']/@value" />
              </Raw>
            </Query>
            <Results>
              <xsl:call-template name="setResource" />
            </Results>
            <xsl:call-template name="setOutcome" />
          </Search>
        </xsl:when>
        <xsl:when test="matches($method, 'GET|OPTIONS|HEAD')">
        <TypeId>SendFromWebService</TypeId>
          <Description>Recieve data from Web Service</Description>
          <Receive>
            <xsl:call-template name="setupParticipants_receive" />
            <Payload>
              <xsl:call-template name="setResource" />
            </Payload>
            <xsl:call-template name="setOutcome" />
          </Receive>
        </xsl:when>
        <xsl:otherwise>
                <TypeId>SendToWebService</TypeId>

          <Description>Send/Access data to Web Service</Description>
          <Send>
            <xsl:call-template name="setupParticipants_send" />
            <Payload>
              <xsl:call-template name="setResource" />
            </Payload>
            <xsl:call-template name="setOutcome" />
          </Send>
        </xsl:otherwise>
      </xsl:choose>
    </EventDetail>
  </xsl:template>

  <!-- Establish the Source and Destination nodes - Receive -->
  <xsl:template name="setupParticipants_receive">
    <xsl:variable name="vServer" select="data[@name = 'vserver']/@value" />
    <xsl:variable name="vServerPort" select="data[@name = 'vserverport']/@value" />
    <xsl:variable name="clientHost" select="data[@name = 'resolvedclient']/@value" />
    <xsl:variable name="clientIP" select="data[@name = 'clientip']/@value" />
    <Source>
      <Device>
        <HostName>
          <xsl:value-of select="$vServer" />
        </HostName>

        <!-- Server Port Number -->
        <xsl:if test="$vServerPort !='-'">
          <Port>
            <xsl:value-of select="$vServerPort" />
          </Port>
        </xsl:if>
      </Device>
    </Source>
    <Destination>
      <Device>
        <xsl:if test="string-length($clientHost) > 0">
          <HostName>
            <xsl:value-of select="$clientHost" />
          </HostName>
        </xsl:if>
        <IPAddress>
          <xsl:value-of select="$clientIP" />
        </IPAddress>

        <!-- Remote Port Number -->
        <xsl:if test="data[@name = 'clientport']/@value !='-'">
          <Port>
            <xsl:value-of select="data[@name = 'clientport']/@value" />
          </Port>
        </xsl:if>
      </Device>
    </Destination>
  </xsl:template>

  <!-- Establish the Source and Destination nodes- Send -->
  <xsl:template name="setupParticipants_send">
    <xsl:variable name="vServer" select="data[@name = 'vserver']/@value" />
    <xsl:variable name="vServerPort" select="data[@name = 'vserverport']/@value" />
    <xsl:variable name="clientHost" select="data[@name = 'resolvedclient']/@value" />
    <xsl:variable name="clientIP" select="data[@name = 'clientip']/@value" />
    <Source>
      <Device>
        <xsl:if test="string-length($clientHost) > 0">
          <HostName>
            <xsl:value-of select="$clientHost" />
          </HostName>
        </xsl:if>
        <IPAddress>
          <xsl:value-of select="$clientIP" />
        </IPAddress>

        <!-- Remote Port Number -->
        <xsl:if test="data[@name = 'port']/@value !='-'">
          <Port>
            <xsl:value-of select="data[@name = 'port']/@value" />
          </Port>
        </xsl:if>
      </Device>
    </Source>
    <Destination>
      <Device>
        <HostName>
          <xsl:value-of select="$vServer" />
        </HostName>

        <!-- Server Port Number -->
        <xsl:if test="$vServerPort !='-'">
          <Port>
            <xsl:value-of select="$vServerPort" />
          </Port>
        </xsl:if>
      </Device>
    </Destination>
  </xsl:template>

  <!-- Define the Resource node -->
  <xsl:template name="setResource">
    <Resource>
      <URL>
        <xsl:value-of select="data[@name = 'url']/data[@name = 'url']/@value" />
      </URL>
      <xsl:if test="data[@name = 'referer']/@value != '-'">
        <Referrer>
          <xsl:value-of select="data[@name = 'referer']/@value" />
        </Referrer>
      </xsl:if>
      <HTTPMethod>
        <xsl:value-of select="data[@name = 'url']/data[@name = 'httpMethod']/@value" />
      </HTTPMethod>
      <HTTPVersion>
        <xsl:value-of select="data[@name = 'url']/data[@name = 'version']/@value" />
      </HTTPVersion>
      <UserAgent>
        <xsl:value-of select="data[@name = 'userAgent']/@value" />
      </UserAgent>
      <xsl:if test="data[@name = 'bytesIn']/@value != '-'">
        <InboundSize>
          <xsl:value-of select="data[@name = 'bytesIn']/@value" />
        </InboundSize>
      </xsl:if>
      <xsl:if test="data[@name = 'bytesOut']/@value != '-'">
        <OutboundSize>
          <xsl:value-of select="data[@name = 'bytesOut']/@value" />
        </OutboundSize>
      </xsl:if>
      <OutboundContentSize>
        <xsl:value-of select="data[@name = 'bytesOutContent']/@value" />
      </OutboundContentSize>
      <RequestTime>
        <xsl:value-of select="data[@name = 'timeM']/@value" />
      </RequestTime>
      <ConnectionStatus>
        <xsl:value-of select="data[@name = 'constatus']/@value" />
      </ConnectionStatus>
      <InitialResponseCode>
        <xsl:value-of select="data[@name = 'responseB']/@value" />
      </InitialResponseCode>
      <ResponseCode>
        <xsl:value-of select="data[@name = 'response']/@value" />
      </ResponseCode>

      <!-- Protocol -->
      <Data Name="Protocol">
        <xsl:attribute name="Value" select="data[@name = 'url']/data[@name = 'protocol']/@value" />
      </Data>
    </Resource>
  </xsl:template>

  <!-- 
  Set up the Outcome node.
  
  We only set an Outcome for an error state. The absence of an Outcome inferrs success
  -->
  <xsl:template name="setOutcome">
    <xsl:variable name="tCliStatus" select="data[@name = 'response']/@value" />
    <xsl:choose>

      <!-- Favour squid specific errors first -->
      <xsl:when test="$tCliStatus > 500">
        <Outcome>
          <Success>false</Success>
          <Description>
            <xsl:call-template name="responseCodeDesc">
              <xsl:with-param name="code" select="$tCliStatus" />
            </xsl:call-template>
          </Description>
        </Outcome>
      </xsl:when>

      <!-- Now check for 'normal' errors -->
      <xsl:when test="$tCliStatus > 400">
        <Outcome>
          <Success>false</Success>
          <Description>
            <xsl:call-template name="responseCodeDesc">
              <xsl:with-param name="code" select="$tCliStatus" />
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