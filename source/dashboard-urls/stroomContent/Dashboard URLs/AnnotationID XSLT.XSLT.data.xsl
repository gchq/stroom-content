<?xml version="1.1" encoding="UTF-8" ?>
<xsl:stylesheet
    xpath-default-namespace="records:2" 
    xmlns="records:2" 
    xmlns:stroom="stroom" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    version="2.0">
    
  <xsl:template match="records">
    <records>
      <xsl:apply-templates />
    </records>
  </xsl:template>
  
  <xsl:template match="record">
    <xsl:variable name="id" select="data[@name='Id']/@value" />
    <xsl:variable name="guid" select="data[@name='Guid']/@value" />
    <xsl:variable name="from_ip" select="data[@name='FromIp']/@value" />
    <xsl:variable name="to_ip" select="data[@name='ToIp']/@value" />
    <xsl:variable name="application" select="data[@name='Application']/@value" />

    <record>
      <xsl:copy-of select="node()"/>
      
      <data name="AnnotationID">
        <xsl:attribute name="value" select="concat($id, '-', $application)" />
      </data>
    </record>
  </xsl:template>
</xsl:stylesheet>