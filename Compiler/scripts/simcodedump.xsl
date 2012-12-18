<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="source">
  <xsl:value-of select="info/@file"/>:<xsl:value-of select="info/@lineStart"/>:<xsl:value-of select="info/@colStart"/>-<xsl:value-of select="info/@lineEnd"/>:<xsl:value-of select="info/@colEnd"/>
  <xsl:text> </xsl:text>
  <xsl:for-each select="type">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <xsl:value-of select="."/>
  </xsl:for-each>
</xsl:template>

<xsl:template match="equation/assign">
  <h3 title="{@type}assignment index={../@index}"><xsl:value-of select="lhs"/> = <xsl:value-of select="rhs"/></h3>
</xsl:template>

<xsl:template match="equation/mixed">
  <h3 title="Mixed system">
    Mixed system index=<xsl:value-of select="../@index"/>
  </h3>
  <p>TODO: Put mixed stuff here...</p>
</xsl:template>

<xsl:template match="equation/when">
  <h3 title="when equation {../@index}">
    when
  <xsl:for-each select="cond">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <xsl:value-of select="."/>
  </xsl:for-each>
  then
  <xsl:value-of select="lhs"/> = <xsl:value-of select="rhs"/>
  </h3>
</xsl:template>

<xsl:template match="equation/statement">
  <h3>Statement</h3>
  <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="equation/residual">
  <h3 title="residual equation {../@index}">0.0 = <xsl:value-of select="."/></h3>
</xsl:template>

<xsl:template match="equation/nonlinear">
  <h3>Nonlinear System (index <xsl:value-of select="../@index"/>)</h3>
  <p>Solves for variables (<xsl:value-of select="count(var)"/> variables, <xsl:value-of select="count(equation)"/> equations): <xsl:for-each select="var">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <a href="#var_{.}"><xsl:value-of select="."/></a>
  </xsl:for-each></p>
  <p>Equations <xsl:for-each select="equation"><a href="#eq_{@index}">#<xsl:value-of select="@index"/></a><xsl:text> </xsl:text></xsl:for-each></p>
  <xsl:for-each select="equation">
    <p><a name="eq_{@index}"></a>Equation <xsl:value-of select="@index"/> (#<xsl:value-of select="position()"/> for <a href="#eq_{../../@index}">NLS <xsl:value-of select="../../@index"/>)</a><xsl:apply-templates select="."/></p>
  </xsl:for-each>
</xsl:template>

<xsl:template name="linear-row">
  <xsl:param name="i"/>
  <xsl:param name="j"/>
  <xsl:param name="stop"/>
  <xsl:choose>
  <xsl:when test="$j &lt; $stop">
    <td class="linear-cell"><div class="linear-cell"><xsl:value-of select="matrix/cell[@row=$i and @col=$j]/equation/residual"/></div></td>
    <xsl:call-template name="linear-row">
      <xsl:with-param name="i" select="$i"/>
      <xsl:with-param name="j" select="$j + 1"/>
      <xsl:with-param name="stop" select="$stop"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <td class="linear-last-cell"><div class="linear-cell"><xsl:value-of select="row/cell[$i+1]"/></div></td>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="linear-matrix">
  <xsl:param name="i"/>
  <xsl:param name="stop"/>
  <xsl:if test="$i &lt; $stop">
    <tr class="linear-row">
    <xsl:call-template name="linear-row">
      <xsl:with-param name="i" select="$i"/>
      <xsl:with-param name="j" select="0" />
      <xsl:with-param name="stop" select="$stop"/>
    </xsl:call-template>
    <xsl:call-template name="linear-matrix">
      <xsl:with-param name="i" select="$i+1"/>
      <xsl:with-param name="stop" select="$stop"/>
    </xsl:call-template>
    </tr>
  </xsl:if>
</xsl:template>

<xsl:template match="equation/linear">
  <h3>Linear equation (index <xsl:value-of select="../@index"/>)</h3>
  Solves for variables (<xsl:value-of select="count(var)"/>): <xsl:for-each select="var">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <a href="#var_{.}"><xsl:value-of select="."/></a>
  </xsl:for-each>
  <table class="linear-matrix">
    <tr>
       <xsl:call-template name="linear-matrix">
         <xsl:with-param name="i" select="0"/>
         <xsl:with-param name="stop" select="count(var)"/>
       </xsl:call-template>
    </tr>
  </table>
  <xsl:for-each select="matrix/cell">
    <p>Cell <xsl:value-of select="@row"/>,<xsl:value-of select="@col"/>: <xsl:apply-templates select="equation/*[1]"/></p>
    <p><xsl:apply-templates select="equation/source"/></p>
    <xsl:apply-templates select="equation/operations/*"/>
  </xsl:for-each>
</xsl:template>

<xsl:template match="operations/substitution">
  <p><span title="substitution">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="before"/>
    <xsl:for-each select="exp">
      <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
      <xsl:value-of select="."/>
    </xsl:for-each>
  </p>
</xsl:template>

<xsl:template match="operations/dummyderivative">
  <p><span title="dummy derivative">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="chosen"/>
    <xsl:for-each select="candidate">
      <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
      <xsl:value-of select="."/>
    </xsl:for-each>
  </p>
</xsl:template>

<xsl:template match="operations/simplify">
  <p><span title="simplify">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="before"/>
    <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
    <xsl:value-of select="after"/>
  </p>
</xsl:template>

<xsl:template match="operations/inline">
  <p><span title="inline">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="before"/>
    <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
    <xsl:value-of select="after"/>
  </p>
</xsl:template>

<xsl:template match="operations/op-residual">
  <p><span title="make an equality equation into residual form">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="lhs"/> = <xsl:value-of select="rhs"/>
    <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
    0.0 = <xsl:value-of select="result"/>
  </p>
</xsl:template>

<xsl:template match="operations/solve">
  <p><span title="solve equation">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="old/lhs"/> = <xsl:value-of select="old/rhs"/>
    <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
    <xsl:value-of select="new/lhs"/> = <xsl:value-of select="new/rhs"/>
    <xsl:if test="assertions/assertion">assertion...</xsl:if></p>
</xsl:template>

<xsl:template match="operations/solved">
  <p><span title="already solved equation">Operation <xsl:number count="*" />: </span>
    <xsl:value-of select="lhs"/><xsl:text> = </xsl:text><xsl:value-of select="rhs"/>
  </p>
</xsl:template>

<xsl:template match="operations/linear-solved">
  <p><span title="solved known linear system of equations">Operation <xsl:number count="*" />: </span>
    TODO: Fix this crap: <xsl:value-of select="."/>
  </p>
</xsl:template>

<xsl:template match="operations/derivative">
  <p><span title="solve">Operation <xsl:number count="*" />: </span>
   d/d<xsl:value-of select="with-respect-to"/><xsl:text> </xsl:text><xsl:value-of select="exp"/>
   <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
   <xsl:value-of select="result"/>
  </p>
</xsl:template>

<xsl:template match="/">
  <html>
  <head>
    <title><xsl:value-of select="simcodedump/@model"/> - SimCodeDump</title>
<style>
table.linear-matrix
{
  max-width:400px;
  word-wrap: break-word;
}
tr.linear-row
{
  width:400px;
  word-wrap: break-word;
}
div.linear-cell
{
  width:auto;
  height:auto;
  font-size: 7pt;
  word-wrap: break-word;
}
td.linear-cell
{
  width:10px;
  word-wrap: break-word;
}
td.linear-last-cell
{
  width:10px;
  word-wrap: break-word;
}
b.arrow
{
  color: blue;
  text-shadow: -1px 0 blue, 0 1px blue, 1px 0 blue, 0 -1px blue;
}
</style>
  </head>
  <body>
  <h2>Equations (<xsl:value-of select="count(simcodedump/equations/equation)"/>)</h2>
    <xsl:for-each select="simcodedump/equations/equation">
      <a name="eq_{@index}"></a>
      <p><xsl:apply-templates select="*[1]"/></p>
      <p><xsl:apply-templates select="source"/></p>
      <xsl:apply-templates select="operations/*"/>
    </xsl:for-each>
  <h2>Variables (<xsl:value-of select="count(simcodedump/variables/variable)"/>)</h2>
    <xsl:for-each select="simcodedump/variables/variable">
      <h3><a name="var_{@name}"><xsl:value-of select="@name"/></a><xsl:if test="@comment"> "<xsl:value-of select="@comment"/>"</xsl:if></h3>
      <p><xsl:apply-templates select="source"/></p>
      <xsl:apply-templates select="operations/*"/>
    </xsl:for-each>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>
