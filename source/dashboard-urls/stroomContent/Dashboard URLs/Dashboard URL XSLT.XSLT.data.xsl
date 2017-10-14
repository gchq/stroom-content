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

    <record>
      <xsl:copy-of select="data"/>

      <xsl:apply-templates select="record[@name='Dashboard']" />

    </record>
  </xsl:template>

  <xsl:template match="record[@name='Dashboard']">
    <xsl:variable name="dashboardTitle" select="data[@name='DashboardTitle']/@value" />
    <xsl:variable name="dashboardUUID" select="data[@name='DashboardUUID']/@value" />

    <xsl:variable name="queryParams">
      <xsl:for-each select="data[not(@name = 'DashboardTitle') and not(@name = 'DashboardUUID')]">
        <xsl:value-of select="@name"/>
        <xsl:text>%3d</xsl:text>
        <xsl:value-of select="@value"/>
        <xsl:text>%20</xsl:text>
      </xsl:for-each>
    </xsl:variable>

    <data name="DashboardURL_browserTab">
      <xsl:attribute name="value" select="stroom:generate-url($dashboardTitle, '__dashboard__', concat('?type=Dashboard', '&amp;', 'uuid=', $dashboardUUID, '&amp;params=', $queryParams), 'BROWSER_TAB')" />
    </data>
    <data name="DashboardURL_stroomTab">
      <xsl:attribute name="value" select="stroom:generate-url($dashboardTitle, '__dashboard__', concat('?type=Dashboard', '&amp;', 'uuid=', $dashboardUUID, '&amp;params=', $queryParams), 'STROOM_TAB')" />
    </data>
  </xsl:template>
</xsl:stylesheet>