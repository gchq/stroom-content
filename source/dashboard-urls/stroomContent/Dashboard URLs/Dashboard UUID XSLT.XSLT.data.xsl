<?xml version="1.1" encoding="UTF-8" ?>
<xsl:stylesheet
        xpath-default-namespace="records:2"
        xmlns:stroom="stroom"
        xmlns="records:2"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        version="2.0">

  <xsl:template match="records">
    <records>
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <xsl:template match="record">
    <xsl:variable name="application" select="data[@name='Application']/@value" />

    <record>
      <xsl:copy-of select="node()"/>

      <record name="Dashboard">
        <data name="Application">
          <xsl:attribute name="value" select="$application" />
        </data>
        <data name="DashboardTitle">
          <xsl:attribute name="value" select="concat($application, ' Dashboard')" />
        </data>
        <data name="DashboardUUID">
          <xsl:attribute name="value" select="'79c0f9d4-b72d-4bb8-8c32-cd46d6b9979f'" />
        </data>
      </record>
    </record>
  </xsl:template>
</xsl:stylesheet>