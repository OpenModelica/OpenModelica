<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="no" indent="no"/>
  <!--                                                     -->
  <xsl:param name="variableName" />
  <xsl:param name="variableStart" />
  <!--                                                     -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <!--                                                     -->
  <xsl:template match="ScalarVariable/node()/@start">
    <xsl:choose>
      <xsl:when test="../../@name = $variableName">
        <xsl:attribute name="start">
          <xsl:value-of select="$variableStart"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="start">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
