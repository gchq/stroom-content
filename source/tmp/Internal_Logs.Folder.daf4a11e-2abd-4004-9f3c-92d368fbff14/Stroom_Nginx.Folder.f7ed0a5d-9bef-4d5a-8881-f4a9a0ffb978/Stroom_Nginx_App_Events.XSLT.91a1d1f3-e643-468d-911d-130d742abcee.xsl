<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">


  <xsl:template match="records">
    <records xsi:schemaLocation="records:2 file://records-v2.0.xsd">
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <xsl:template match="record">
    <record>
      <xsl:apply-templates/>
    </record>
  </xsl:template>
  
  <xsl:template match="data[@name='logLevel']">
    <data name="logLevel">
    <xsl:attribute name="value" select="upper-case(@value)"/>  
    </data>
    
  </xsl:template>
  <xsl:template match="data[@name!='logLevel']">
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
