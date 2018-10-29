<?xml version="1.1" encoding="UTF-8" ?>
<xsl:stylesheet
        xpath-default-namespace="records:2"
        xmlns="records:2"
        xmlns:stroom="stroom"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:json="http://www.w3.org/2013/XSL/json"
        version="2.0">

  <xsl:template match="records">
    <records>
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <xsl:template match="record">
    <!-- Extract and compose the annotation ID -->
    <xsl:variable name="id" select="data[@name='Id']/@value" />
    <xsl:variable name="application" select="data[@name='Application']/@value" />
    <xsl:variable name="annotationID" select="concat($id, '-', $application)" />

    <!-- Fetch the Annotation from the Service -->
    <xsl:variable name="annotation" select="stroom:fetch-json('annotations-service', concat('single/', $annotationID))" />

    <record>
      <xsl:copy-of select="node()"/>

      <data name="Status">
        <xsl:attribute name="value" select="$annotation/json:map/json:string[@key='status']" />
      </data>

      <data name="Assigned_To">
        <xsl:attribute name="value" select="$annotation/json:map/json:string[@key='assignTo']" />
      </data>

      <data name="AnnotationURL_dialog">
        <xsl:attribute name="value" select="stroom:generate-url($annotationID, '__annotations-ui__', concat('single/', $annotationID), 'DIALOG')" />
      </data>
      <data name="AnnotationURL_stroomTab">
        <xsl:attribute name="value" select="stroom:generate-url($annotationID, '__annotations-ui__', concat('single/', $annotationID), 'STROOM_TAB')" />
      </data>
    </record>
  </xsl:template>
</xsl:stylesheet>