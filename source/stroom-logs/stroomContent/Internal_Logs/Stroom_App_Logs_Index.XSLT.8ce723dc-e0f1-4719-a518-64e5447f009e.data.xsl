<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

  <!-- Ingest the Evts tree -->
  <xsl:template match="records">
    <records xsi:schemaLocation="records:2 file://records-v2.0.xsd">
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <!-- Main record template for single Evt event -->
  <xsl:template match="record">

    <!-- Build the record element -->
    <record>

      <!-- Add the Stream/EventIds -->
      <data name="StreamId">
        <xsl:attribute name="value" select="@StreamId" />
      </data>
      <data name="EventId">
        <xsl:attribute name="value" select="@EventId" />
      </data>

      <!-- Copy the data items from the record, renaming as required -->
      <data name="Log Level">
        <xsl:attribute name="value" select="data[@name='logLevel']/@value" />
      </data>
      <data name="Event Time">
        <xsl:attribute name="value" select="data[@name='dateTime']/@value" />
      </data>
      <data name="Thread">
        <xsl:attribute name="value" select="data[@name='thread']/@value" />
      </data>
      <data name="Logger">
        <xsl:attribute name="value" select="data[@name='logger']/@value" />
      </data>
      <data name="Message">
        <xsl:attribute name="value" select="data[@name='message']/@value" />
      </data>
      <data name="System">
        <xsl:attribute name="value" select="data[@name='system']/@value" />
      </data>
      <data name="Hostname">
        <xsl:attribute name="value" select="data[@name='hostName']/@value" />
      </data>
      <data name="Container Name">
        <xsl:attribute name="value" select="data[@name='containerName']/@value" />
      </data>
    </record>
  </xsl:template>
</xsl:stylesheet>