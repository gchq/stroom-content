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
    <xsl:variable name="annotationID" select="data[@name='AnnotationID']/@value" />

    <record>
      <xsl:copy-of select="node()"/>
      
      <data name="AnnotationURL">
        <xsl:attribute name="value" select="concat('[', $annotationID, '](__annotations-ui__:3000/', $annotationID, ')')" />
      </data>
    </record>
  </xsl:template>
</xsl:stylesheet>