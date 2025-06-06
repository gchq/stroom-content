<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="event-logging:3" xmlns="plan-b:1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="Events">
    <plan-b xsi:schemaLocation="plan-b:1 file://plan-b-v1.0.xsd event-logging:3 file://event-logging-v3.0.0.xsd" version="1.0">
      <xsl:apply-templates />
    </plan-b>
  </xsl:template>
  <xsl:template match="Event">
    <xsl:if test="EventDetail//Data[@Name='LineNo']/@Value">
      <metric>
        <map>event_metric</map>
        <tags>
          <tag>
            <name>user</name>
            <value>
              <xsl:value-of select="EventSource/User/Id" />
            </value>
          </tag>
        </tags>
        <time>
          <xsl:value-of select="EventTime/TimeCreated" />
        </time>
        <value>
          <xsl:value-of select="EventDetail//Data[@Name='LineNo']/@Value" />
        </value>
      </metric>
      <metric>
        <map>event_metric_2</map>
        <tags>
          <tag>
            <name>user</name>
            <value>
              <xsl:value-of select="EventSource/User/Id" />
            </value>
          </tag>
        </tags>
        <time>
          <xsl:value-of select="EventTime/TimeCreated" />
        </time>
        <value>
          <xsl:value-of select="EventDetail//Data[@Name='LineNo']/@Value" />
        </value>
      </metric>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
