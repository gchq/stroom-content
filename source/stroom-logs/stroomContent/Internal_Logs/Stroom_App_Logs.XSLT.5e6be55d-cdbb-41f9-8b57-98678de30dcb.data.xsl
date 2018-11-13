<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xpath-default-namespace="records:2" xmlns="records:2" xmlns:stroom="stroom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

  <!-- Define which log levels to process -->
  <xsl:variable name="LOG_LEVEL_WHITELIST" select="tokenize('ERROR,WARN,INFO', ',')" />

  <!-- Ingest the Evts tree -->
  <xsl:template match="records">
    <records xsi:schemaLocation="records:2 file://records-v2.0.xsd">
      <xsl:apply-templates />
    </records>
  </xsl:template>

  <!-- Main record template for single Evt event -->
  <xsl:template match="record">

    <!-- Check if we want this log level -->
    <xsl:if test="index-of($LOG_LEVEL_WHITELIST, ./data[@name='logLevel']/@value)[1] > 0">

      <!--
      <xsl:variable name="_dateTime" select="data[@name='dateTime']/@value" />
      <xsl:variable name="_formattedDateTime" select="stroom:format-date($_dateTime, 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX')" />
      -->
      <xsl:variable name="_myhost" select="translate(stroom:feed-attribute('MyHost'),'&quot;', '')" />
      <xsl:variable name="_myip" select="translate(stroom:feed-attribute('MyIPaddress'),'&quot;', '')" />
      <xsl:variable name="_mymeta" select="translate(stroom:feed-attribute('MyMeta'),'&quot;', '')" />
      <xsl:variable name="_myns" select="translate(stroom:feed-attribute('MyNameServer'),'&quot;', '')" />
      <xsl:variable name="_deviceHostName">

        <!-- For the device host name we choose, in order, contents of
        - MyHost header variable in post
        - FQDN portion of MyMeta header variable in post
        - @host attribute on the event element
        - the 'RemoteHost' attribute that Stroom's proxy evaluated
        -->
        <xsl:choose>
          <xsl:when test="string-length($_myhost) > 0 and contains($_myhost, ' ')">
            <xsl:value-of select="substring-before($_myhost, ' ')" />
          </xsl:when>
          <xsl:when test="string-length($_myhost) > 0">
            <xsl:value-of select="$_myhost" />
          </xsl:when>
          <xsl:when test="string-length($_mymeta) > 0">
            <xsl:value-of select="substring-before(substring-after($_mymeta,'FQDN:'),'\')" />
          </xsl:when>
          <xsl:when test="@host">
            <xsl:value-of select="@host" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="stroom:feed-attribute('RemoteHost')" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="_deviceIP">

        <!-- For the device ip address we choose, in order, contents of
        - MyHost header variable in post
        - ipaddress portion of MyMeta header variable in post
        - the 'RemoteAddress' attribute that Stroom's proxy evaluated
        -->
        <xsl:choose>
          <xsl:when test="string-length($_myip) > 0 and contains($_myip, ' ')">
            <xsl:value-of select="substring-before($_myip, ' ')" />
          </xsl:when>
          <xsl:when test="string-length($_myip) > 0 and contains($_myip, '%')">
            <xsl:value-of select="substring-before($_myip, '%')" />
          </xsl:when>
          <xsl:when test="string-length($_myip) > 0">
            <xsl:value-of select="$_myip" />
          </xsl:when>
          <xsl:when test="string-length($_mymeta) > 0">
            <xsl:value-of select="substring-before(substring-after($_mymeta,'ipaddress:'),'\')" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="stroom:feed-attribute('RemoteAddress')" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Build the record element -->
      <record>
        <xsl:copy-of select="./data" />
        <data name="system">
          <xsl:attribute name="value" select="stroom:feed-attribute('System')" />
        </data>
        <data name="environment">
          <xsl:attribute name="value" select="stroom:feed-attribute('Environment')" />
        </data>
        <data name="containerName">
          <xsl:attribute name="value" select="stroom:feed-attribute('ContainerName')" />
        </data>
        <data name="feedName">
          <xsl:attribute name="value" select="stroom:feed-name()" />
        </data>
        <data name="hostName">

          <!-- TODO log sender needs to set the container's hostname in the meta -->
          <xsl:attribute name="value" select="$_deviceHostName" />
        </data>

        <!-- TODO How do we identify a docker container, e.g. the host's hostanme + some form of container id? -->
      </record>
    </xsl:if>
  </xsl:template>
  <xsl:template name="addFeedAttribute">
    <xsl:param name="dataItemName" />
    <xsl:param name="feedAttributeName" />
    <data>
      <xsl:attribute name="name" select="dataItemName" />
      <xsl:attribute name="value" select="stroom:feed-attribute($feedAttributeName)" />
    </data>
  </xsl:template>
</xsl:stylesheet>