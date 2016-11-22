<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="event-logging:3" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
  <xsl:template match="records">
    <Events xsi:schemaLocation="event-logging:3 file://event-logging-v3.0.0.xsd" Version="3.0.0">
      <xsl:apply-templates />
    </Events>
  </xsl:template>
  <xsl:template match="record">
    <xsl:variable name="ipAddress" select="data[1]/@value" />
    <xsl:variable name="userId" select="data[3]/@value" />
    <xsl:variable name="date" select="data[4]/@value" />
    <xsl:variable name="formattedDate" select="stroom:format-date($date, 'dd/MMM/yyyy:HH:mm:ss Z')" />
    <xsl:variable name="rawUrl" select="data[5]/data[2]/@value" />
    <xsl:variable name="method" select="data[5]/data[1]/@value" />
    <xsl:variable name="responseCode" select="data[6]/@value" />
    <xsl:variable name="cacheResponse" select="data[8]/@value" />
    <xsl:variable name="userAgent" select="data[9]/data[@name='User-Agent']/@value" />
    <xsl:variable name="squidError" select="data[9]/data[@name='X-Squid-Error']/@value" />
    <xsl:variable name="referer" select="escape-html-uri(data[9]/data[@name='Referer']/@value)" />
    <xsl:variable name="userStrip" select="substring-before(data[3]/@value,'_')" />
    <Event>
      <EventTime>
        <TimeCreated>
          <xsl:value-of select="$formattedDate" />
        </TimeCreated>
      </EventTime>
      <EventSource>
        <System>
          <Name>

            <!-- TODO use feedname if not available -->
            <xsl:value-of select="stroom:feed-attribute('System')" />
          </Name>

          <!-- TODO hard code to OPS if not available -->
          <Environment>
            <xsl:value-of select="stroom:feed-attribute('Environment')" />
          </Environment>
        </System>
        <Generator>Squid</Generator>
        <Device>
          <IPAddress>
            <xsl:value-of select="stroom:feed-attribute('RemoteAddress')" />
          </IPAddress>
        </Device>
        <Client>
          <IPAddress>
            <xsl:value-of select="$ipAddress" />
          </IPAddress>
        </Client>
        <xsl:if test="$userId != '-'">
          <User>
            <Id>
              <xsl:value-of select="$userId" />
            </Id>
          </User>
        </xsl:if>
        <Data>
          <xsl:attribute name="Name">Feed</xsl:attribute>
          <xsl:attribute name="Value">
            <xsl:value-of select="stroom:feed-name()" />
          </xsl:attribute>
        </Data>
      </EventSource>
      <EventDetail>
        <TypeId>View</TypeId>
        <View>
          <WebPage>
            <URL>
              <xsl:value-of select="$rawUrl" />
            </URL>
            <xsl:if test="$referer != ''">
              <Referrer>
                <xsl:value-of select="$referer" />
              </Referrer>
            </xsl:if>
            <SessionId>
              <xsl:value-of select="data[10]/data[@name='Set-Cookie']/@value" />
            </SessionId>
            <xsl:if test="$method != 'NONE' and matches($method,'^[GHPDUTOC]','i')">
              <HTTPMethod>
                <xsl:value-of select="$method" />
              </HTTPMethod>
            </xsl:if>
            <UserAgent>
              <xsl:value-of select="$userAgent" />
            </UserAgent>
            <ResponseCode>
              <xsl:value-of select="$responseCode" />
            </ResponseCode>
            <MimeType>
              <xsl:value-of select="replace(data[10]/data[@name='Content-Type'][1]/@value,';.*$','')" />
            </MimeType>
            <Data Name="Size">
              <xsl:attribute name="Value">
                <xsl:value-of select="data[7]/@value" />
              </xsl:attribute>
            </Data>
            <Data Name="CACHE_RESPONSE">
              <xsl:attribute name="Value">
                <xsl:value-of select="$cacheResponse" />
              </xsl:attribute>
            </Data>
            <Data Name="X-Squid-Error">
              <xsl:attribute name="Value">
                <xsl:value-of select="$squidError" />
              </xsl:attribute>
            </Data>
          </WebPage>
          <xsl:if test="contains($cacheResponse,'DENIED')">
            <Outcome>
              <Success>false</Success>
            </Outcome>
          </xsl:if>
        </View>
      </EventDetail>
    </Event>
  </xsl:template>
</xsl:stylesheet>