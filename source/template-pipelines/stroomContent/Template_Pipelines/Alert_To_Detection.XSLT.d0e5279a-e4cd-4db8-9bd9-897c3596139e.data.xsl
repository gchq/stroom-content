<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="detection:1" xmlns:rec="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
  <xsl:template match="/records">
    <detections xsi:schemaLocation="detection:1 file://detection-v1.0.xsd">
      <xsl:apply-templates />
    </detections>
  </xsl:template>
  <xsl:template match="record">
    <detection>
      <detectTime>
        <xsl:value-of select="data[@name='alertDetectTime']/@value" />
      </detectTime>
      <detectorName>Stroom Alerting</detectorName>
      <detectorEnvironment>Stroom</detectorEnvironment>
      <headline>
        <xsl:value-of select="data[@name='alertDashboardName']/@value" />
      </headline>
      <detail>
        <xsl:value-of select="data[@name='alertTableName']/@value" />
      </detail>
      <xsl:apply-templates select="data[@name!='alertDetectTime' and @name!='alertDashboardName' and @name!='alertTableName']" />
      <linkedEvents>
        <linkedEvent>
          <streamId>
            <xsl:value-of select="data[@name='alertOriginalStreamId']/@value" />
          </streamId>
          <eventId>
            <xsl:value-of select="data[@name='alertOriginalEventId']/@value" />
          </eventId>
        </linkedEvent>
      </linkedEvents>
    </detection>
  </xsl:template>
  <xsl:template match="data">
    <xsl:element name="value">
      <xsl:attribute name="name">
        <xsl:value-of select="@name" />
      </xsl:attribute>
      <xsl:value-of select="@value" />
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>