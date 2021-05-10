<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="event-logging:3" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">

  <!-- Template for the root records element -->
  <xsl:template match="records">
    <Events xsi:schemaLocation="event-logging:3 file://event-logging-v3.4.2.xsd" Version="3.4.2">
      <xsl:apply-templates />
    </Events>
  </xsl:template>

  <!-- template for any record element containing a url data item -->
  <xsl:template match="record[data[@name = 'url']]">
    <Event>
      <xsl:apply-templates select="." mode="eventTime" />
      <xsl:apply-templates select="." mode="eventSource" />
      <xsl:apply-templates select="." mode="eventDetail" />
    </Event>
  </xsl:template>

  <!-- Template for event time -->
  <xsl:template match="node()" mode="eventTime">
    <xsl:variable name="date" select="data[@name = 'time']/@value" />
    <xsl:variable name="formattedDate" select="stroom:format-date($date, 'dd/MMM/yyyy:HH:mm:ss Z')" />
    <EventTime>
      <TimeCreated>
        <xsl:value-of select="$formattedDate" />
      </TimeCreated>
    </EventTime>
  </xsl:template>

  <!-- Template for event source-->
  <xsl:template match="node()" mode="eventSource">
    <EventSource>
      <System>
        <Name>
          <xsl:value-of select="stroom:feed-attribute('System')" />
        </Name>
        <Environment>
          <xsl:value-of select="stroom:feed-attribute('Environment')" />
        </Environment>
      </System>
      <Generator>Apache HTTPD</Generator>
      <Device>
        <IPAddress>
          <xsl:value-of select="stroom:feed-attribute('RemoteAddress')" />
        </IPAddress>
      </Device>
      <Client>
        <xsl:choose>
          <xsl:when test="matches(data[@name = 'host']/@value,'^[0-9.]+$')">
            <IPAddress>
              <xsl:value-of select="data[@name = 'host']/@value" />
            </IPAddress>
          </xsl:when>
          <xsl:otherwise>
            <HostName>
              <xsl:value-of select="data[@name = 'host']/@value" />
            </HostName>
          </xsl:otherwise>
        </xsl:choose>
      </Client>
      <xsl:if test="data[@name = 'user']/@value !='-'">
        <xsl:apply-templates select="data[@name = 'user']" mode="userElement" />
      </xsl:if>
    </EventSource>
  </xsl:template>

  <!-- Template for event detail -->
  <xsl:template match="node()" mode="eventDetail">
    <EventDetail>
      <TypeId>
        <xsl:value-of select="data[@name = 'httpMethod']/@value" />
      </TypeId>
      <View>
        <Resource>
          <Type>WebPage</Type>
          <URL>
            <xsl:value-of select="data[@name = 'url']/@value" />
          </URL>
          <xsl:if test="data[@name = 'referrer']/@value != '-'">
            <Referrer>
              <xsl:value-of select="data[@name = 'referrer']/@value" />
            </Referrer>
          </xsl:if>
          <HTTPMethod>
            <xsl:value-of select="data[@name = 'httpMethod']/@value" />
          </HTTPMethod>
          <UserAgent>
            <xsl:value-of select="data[@name = 'userAgent']/@value" />
          </UserAgent>
          <ResponseCode>
            <xsl:value-of select="data[@name = 'response']/@value" />
          </ResponseCode>
          <xsl:if test="data[@name = 'size']/@value != '-'">
            <Data Name="Size">
              <xsl:attribute name="Value" select="data[@name = 'size']/@value" />
            </Data>
          </xsl:if>
          <xsl:if test="data[@name = 'requestDuration']/@value">
            <Data Name="RequestDuration">
              <!--Standard unit is microseconds for Apache log-->
              <xsl:attribute name="Value" select="data[@name = 'requestDuration']/@value" />
            </Data>
          </xsl:if>
        </Resource>
      </View>
    </EventDetail>
  </xsl:template>

  <!-- Template for the user element -->
  <xsl:template match="node()" mode="userElement">
    <User>
      <Id>
        <xsl:value-of select="@value" />
      </Id>
    </User>
  </xsl:template>
</xsl:stylesheet>
