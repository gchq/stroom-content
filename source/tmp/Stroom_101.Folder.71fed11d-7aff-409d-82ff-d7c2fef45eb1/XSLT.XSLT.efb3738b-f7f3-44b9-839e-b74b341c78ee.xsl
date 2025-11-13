<?xml version="1.1" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
  <xsl:template match="records">
    <Events>
      <xsl:apply-templates />
    </Events>
  </xsl:template>
  <xsl:template match="record">
    <xsl:variable name="id" select="data[@name='id']/@value" />
    <xsl:variable name="guid" select="data[@name='guid']/@value" />
    <xsl:variable name="from_ip" select="data[@name='from_ip']/@value" />
    <xsl:variable name="to_ip" select="data[@name='to_ip']/@value" />
    <xsl:variable name="application" select="data[@name='application']/@value" />

    <Event>
      <Id><xsl:value-of select="$id" /></Id>
      <Guid><xsl:value-of select="$guid" /></Guid>
      <FromIp><xsl:value-of select="$from_ip" /></FromIp>
      <ToIp><xsl:value-of select="$to_ip" /></ToIp>
      <Application><xsl:value-of select="$application" /></Application>
    </Event>
  </xsl:template>
</xsl:stylesheet>
