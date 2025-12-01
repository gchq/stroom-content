<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="http://www.w3.org/2013/XSL/json" xmlns="plan-b:2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/">
    <plan-b xsi:schemaLocation="plan-b:2 file://plan-b-v2.0.xsd" version="2.0">
      <xsl:apply-templates select="/map/map/array/map/array/map/array[@key = 'spans']" />
    </plan-b>
  </xsl:template>
  <xsl:template match="array[@key = 'spans']/map">
    <trace>
      <map>test_traces</map>
      <span>
        <xsl:apply-templates select="string[@key = 'traceId']" />
        <xsl:apply-templates select="string[@key = 'spanId']" />
        <xsl:apply-templates select="string[@key = 'parentSpanId']" />
        <xsl:apply-templates select="number[@key = 'traceState']" />
        <xsl:apply-templates select="number[@key = 'flags']" />
        <xsl:apply-templates select="string[@key = 'name']" />
        <xsl:apply-templates select="number[@key = 'kind']" />
        <xsl:apply-templates select="string[@key = 'startTimeUnixNano']" />
        <xsl:apply-templates select="string[@key = 'endTimeUnixNano']" />
        <xsl:apply-templates select="array[@key = 'attributes']" />
        <xsl:apply-templates select="number[@key = 'droppedAttributesCount']" />
        <xsl:apply-templates select="array[@key = 'events']" />
        <xsl:apply-templates select="number[@key = 'droppedEventsCount']" />
        <xsl:apply-templates select="array[@key = 'links']" />
        <xsl:apply-templates select="number[@key = 'droppedLinksCount']" />
      </span>
    </trace>
  </xsl:template>
  <xsl:template match="string[@key = 'traceId']">
    <traceId>
      <xsl:value-of select="." />
    </traceId>
  </xsl:template>
  <xsl:template match="string[@key = 'spanId']">
    <spanId>
      <xsl:value-of select="." />
    </spanId>
  </xsl:template>
  <xsl:template match="string[@key = 'parentSpanId']">
    <parentSpanId>
      <xsl:value-of select="." />
    </parentSpanId>
  </xsl:template>
  <xsl:template match="string[@key = 'traceState']">
    <traceState>
      <xsl:value-of select="." />
    </traceState>
  </xsl:template>
  <xsl:template match="number[@key = 'flags']">
    <flags>
      <xsl:value-of select="." />
    </flags>
  </xsl:template>
  <xsl:template match="string[@key = 'name']">
    <name>
      <xsl:value-of select="." />
    </name>
  </xsl:template>
  <xsl:template match="number[@key = 'kind']">
    <kind>
      <xsl:choose>
        <xsl:when test=". = 0">INTERNAL</xsl:when>
        <xsl:when test=". = 1">SERVER</xsl:when>
        <xsl:when test=". = 2">CLIENT</xsl:when>
        <xsl:when test=". = 3">PRODUCER</xsl:when>
        <xsl:when test=". = 4">CONSUMER</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </kind>
  </xsl:template>
  <xsl:template match="string[@key = 'startTimeUnixNano']">
    <startTimeUnixNano>
      <xsl:value-of select="." />
    </startTimeUnixNano>
  </xsl:template>
  <xsl:template match="string[@key = 'endTimeUnixNano']">
    <endTimeUnixNano>
      <xsl:value-of select="." />
    </endTimeUnixNano>
  </xsl:template>
  <xsl:template match="array[@key = 'attributes']">
    <attributes>
      <xsl:apply-templates select="map" mode="keyValue" />
    </attributes>
  </xsl:template>
  <xsl:template match="number[@key = 'droppedAttributesCount']">
    <droppedAttributesCount>
      <xsl:value-of select="." />
    </droppedAttributesCount>
  </xsl:template>
  <xsl:template match="array[@key = 'events']">
    <events>
      <xsl:value-of select="." />
    </events>
  </xsl:template>
  <xsl:template match="number[@key = 'droppedEventsCount']">
    <droppedEventsCount>
      <xsl:value-of select="." />
    </droppedEventsCount>
  </xsl:template>
  <xsl:template match="array[@key = 'links']">
    <links>
      <xsl:value-of select="." />
    </links>
  </xsl:template>
  <xsl:template match="number[@key = 'droppedLinksCount']">
    <droppedLinksCount>
      <xsl:value-of select="." />
    </droppedLinksCount>
  </xsl:template>
  <xsl:template match="map" mode="keyValue">
    <keyValue>
      <key>
        <xsl:value-of select="string[@key = 'key']" />
      </key>
      <xsl:apply-templates select="./map[@key='value']/*" mode="anyValue" />
    </keyValue>
  </xsl:template>
  <xsl:template match="node()" mode="anyValue">
    <xsl:element name="{@key}">
      <xsl:value-of select="text()" />
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>