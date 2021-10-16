<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="event-logging:3" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.0">

  <!--Basic usage function-->
 <xsl:function name="stroom:json" as="xs:string">
    <xsl:param name="input" as="node()" />
    <xsl:value-of select="stroom:json($input,'')" />
  </xsl:function>
  

  <!--Advanced usage function, can create more consistent JSON by always creating arrays for specified elements-->
  <!--The list of elements that should always be contained within an array are provided as a single comma delimited string-->
  <!--Each item in the list is of the format ParentTag/ElementTag or */ElementTag if it doesn't matter what the parent is-->
  <!--For example '*/Data,Groups/Group,Permissions/Permission,Permission/Allow,Permission/Deny,DataSources/DataSource,*/And,*/Or,*/Not,To/User,Cc/User,Bcc/User,Authorisations/Auth'-->
    <xsl:function name="stroom:json" as="xs:string">
    <xsl:param name="input" as="node()" />
    <xsl:param name="multipleValueElements" as="xs:string" />
    <xsl:variable name="jsonXML">
      <xsl:call-template name="stroom:create-json-xml">
        <xsl:with-param name="input" select="$input" />
        <xsl:with-param name="multipleValueTagPairs" select="$multipleValueElements" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="xml-to-json($jsonXML)" />
    
  </xsl:function>

  <!--<Events> maps to <array> -->
  <xsl:template name="stroom:create-json-xml">
    <xsl:param name="input" />
    <xsl:param name="multipleValueTagPairs" />
    <array xsi:schemaLocation="http://www.w3.org/2005/xpath-functions file://xpath-functions.xsd">
      <xsl:apply-templates mode="createJsonXmlnoKey" select="$input">
        <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
      </xsl:apply-templates>
    </array>
  </xsl:template>

  <!--For values of elements and attributes-->
  <xsl:template match="*[not(*)] | @*" mode="createJsonXmlwithKey">
    <xsl:element name="string">
      <xsl:attribute name="key">
        <xsl:value-of select="name()" />
      </xsl:attribute>
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!--Standard version-->
  <xsl:template match="node()" mode="createJsonXmlwithKey">
    <xsl:param name="multipleValueTagPairs" />
    <xsl:element name="map">
      <xsl:attribute name="key">
        <xsl:value-of select="name(.)" />
      </xsl:attribute>
      <xsl:apply-templates select="." mode="createJsonXmlInternal">
        <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <!--Version for use within an array-->
  <xsl:template match="node()" mode="createJsonXmlnoKey">
    <xsl:param name="multipleValueTagPairs" />
    <xsl:element name="map">
      <xsl:apply-templates select="." mode="createJsonXmlInternal">
        <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <!--The guts of the recursive template-->
  <xsl:template match="node()" mode="createJsonXmlInternal">
    <xsl:param name="multipleValueTagPairs" />
    <xsl:variable name="currentNode" select="." />

    <!--Do attributes-->
    <xsl:apply-templates select="@*" mode="createJsonXmlwithKey" />

    <!--Group to deal with multiples-->
    <xsl:for-each-group select="*" group-by="name()">
      <xsl:variable name="alwaysArray" select="contains($multipleValueTagPairs,concat($currentNode/name(),'/',current-group()/name())) or contains($multipleValueTagPairs,concat('*','/',current-group()/name()))" />
      <xsl:choose>
        <xsl:when test="count(current-group()) gt 1 or $alwaysArray">
          <xsl:element name="array">
            <xsl:attribute name="key">
              <xsl:value-of select="current-grouping-key()" />
            </xsl:attribute>
            <xsl:for-each select="current-group()">
              <xsl:apply-templates select="." mode="createJsonXmlnoKey">
                <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="createJsonXmlwithKey">
            <xsl:with-param name="multipleValueTagPairs" select="$multipleValueTagPairs" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
</xsl:stylesheet>
