<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="statistics:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

  <!-- Ingest the records tree -->
  <xsl:template match="records">
    <statistics xsi:schemaLocation="statistics:2 file://statistics-v2.0.xsd">
      <xsl:apply-templates />
    </statistics>
  </xsl:template>

  <!-- Main record template for single Evt event -->
  <xsl:template match="record">

    <!-- We only want stat events for WARN/ERROR -->
    <xsl:if test="./data[@name='logLevel']/@value = ('ERROR', 'WARN')">

      <!-- Build the stat element -->
      <statistic>
        <time>
          <xsl:value-of select="data[@name='dateTime']/@value" />
        </time>

        <!-- Alsways dealing with a single log entry so hard-coded to one -->
        <count>1</count>
        
        <!-- Define the tags for the stat -->
        <tags>
          <tag name="System">
            <xsl:attribute name="value" select="data[@name='system']/@value" />
          </tag>
          <tag name="Hostname">
            <xsl:attribute name="value" select="data[@name='hostName']/@value" />
          </tag>
          <tag name="Logger">
            <xsl:attribute name="value" select="data[@name='logger']/@value" />
          </tag>
          <tag name="Log Level">
            <xsl:attribute name="value" select="data[@name='logLevel']/@value" />
          </tag>
        </tags>
      </statistic>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>