<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="event-logging:3" xmlns="http://www.w3.org/2013/XSL/json" xmlns:stroom="stroom" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3">
  <xsl:include href="stroom-json" />
  <xsl:include href="events-multipleValueTagPairs" />

  <!--Go-->
  <xsl:template match="/">
    <xsl:call-template name="stroom:create-json-xml">
      <xsl:with-param name="input" select="." />
      <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
    </xsl:call-template>
  </xsl:template>

  <!-- Suppress other text -->
  <xsl:template match="text()" />
</xsl:stylesheet>