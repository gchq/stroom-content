<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="event-logging:3" xmlns="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.0">
  <xsl:include href="stroom-json" />
  <xsl:include href="events-multipleValueTagPairs" />

  <!--Root template /Events-->
  <xsl:template match="/Events">
    <records xsi:schemaLocation="records:2 file://records-v2.0.xsd" version="2.0">
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <!--Record for each Event element-->
  <xsl:template match="Event">
    <record>
      <data name="StreamId">
        <xsl:attribute name="value" select="@StreamId" />
      </data>
      <data name="EventId">
        <xsl:attribute name="value" select="@EventId" />
      </data>
      <data name="Json">
        <xsl:attribute name="value" select="stroom:json (.,$multipleValueTagPairs)" />
      </data>
    </record>
  </xsl:template>

  <!-- Suppress other text -->
  <xsl:template match="text()" />
</xsl:stylesheet>