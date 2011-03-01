<?xml version="1.0"?>

<!DOCTYPE xsl:stylesheet [
<!ENTITY nbsp "&#xa0;"> <!--known for HTML output, not in XML-->
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" >

<xsl:template match="/simulation">
<html>
<head>
  <title>TITLE</title>
  <style type="text/css">
    table {border-style: solid;border-spacing: 0;}
    th {
      padding: 6px;
      text-align: right;
      border-style: solid;
      border-width: 0 0 1px 1px;
    }
    th.name {text-align: left;}
    td {
      padding: 6px;
      text-align: right;
      border-style: solid;
      border-width: 0 0 1px 1px;
    }
    td.name {text-align: left;}
    img.thumb {width: 32px;}
    abbr {border-bottom:1px dotted;}
    a img {border: 1px solid black;}
  </style>
</head>

<body>
<h1>Model information for <xsl:value-of select="modelinfo/name"/></h1>

<h2>Information</h2>
<p>All times are measured using a real-time wall clock. This means context switching produces bad worst-case execution times (max times) for blocks. If you want better results, use a CPU-time clock or run the command using real-time priviliges (avoiding context switches).</p>
<p>Note that for blocks where the individual execution time is close to the accuracy of the real-time clock, the maximum measured time may deviate a lot from the average.</p>
<p>For more details, see <a href="{modelinfo/prefix}_prof.csv"><xsl:value-of select="modelinfo/name"/>_prof.csv</a>.</p>

<h2>Summary</h2>
  <p>What solver/settings were used?</p>
  <table>
  <tr><th class="name">Task</th><th>Time</th><th><abbr title="Fraction of total simulation time">Fraction</abbr></th></tr>
  <tr><td class="name"><abbr title="Choosing solver, allocating data structures, etc (does not include reading the parameter start-values from file)">Pre-Initialization</abbr></td><td><xsl:value-of select="modelinfo/preinitTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/preinitTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Initialization</td><td><xsl:value-of select="modelinfo/initTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/initTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Event-handling</td><td><xsl:value-of select="modelinfo/eventTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/eventTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Creating output file</td><td><xsl:value-of select="modelinfo/outputTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/outputTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Linearization</td><td><xsl:value-of select="modelinfo/linearizeTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/linearizeTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Time steps (incl.integration?)</td><td><xsl:value-of select="modelinfo/totalStepsTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/totalStepsTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Overhead</td><td><xsl:value-of select="modelinfo/overheadTime"/></td><td><xsl:value-of select="format-number(100 * modelinfo/overheadTime div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Unknown</td><td><xsl:value-of select="modelinfo/totalTime - modelinfo/overheadTime - modelinfo/totalStepsTime - modelinfo/linearizeTime - modelinfo/outputTime - modelinfo/eventTime - modelinfo/initTime"/></td>
  <td><xsl:value-of select="format-number(100 * (modelinfo/totalTime - modelinfo/overheadTime - modelinfo/totalStepsTime - modelinfo/linearizeTime - modelinfo/outputTime - modelinfo/eventTime - modelinfo/initTime - modelinfo/preinitTime) div modelinfo/totalTime,'##0.00')"/>%</td></tr>
  <tr><td class="name">Total simulation time</td><td><xsl:value-of select="modelinfo/totalTime"/></td><td>100.00%</td></tr>
  </table>

<h2>Global Steps</h2>
  <table>
  <tr><th>&nbsp;</th><th>Steps</th><th>Total Time</th><th><abbr title="Fraction of total simulation time">Fraction</abbr></th><th>Average Time</th><th><abbr title="The maximum accumulated time of this action during a single time step">Max Time</abbr></th><th><abbr title="Deviation from average execution time">Deviation</abbr></th></tr>
  <tr>
     <td><a href="{modelinfo/prefix}_prof.999.svg"><img class="thumb" src="{modelinfo/prefix}_prof.999.thumb.png" alt="Graph thumbnail" /></a></td>
     <td><xsl:value-of select="modelinfo/numStep"/></td>
     <td><xsl:value-of select="modelinfo/totalStepsTime"/></td>
     <td><xsl:value-of select="format-number(100 * modelinfo/totalStepsTime div modelinfo/totalTime,'##0.00')"/>%</td>
     <td><xsl:value-of select="modelinfo/totalStepsTime div modelinfo/numStep"/></td>
     <td><xsl:value-of select="modelinfo/maxTime"/></td>
     <td><xsl:value-of select="format-number((modelinfo/numStep * modelinfo/maxTime div modelinfo/totalStepsTime)-1,'##0.00')"/>x</td>
  </tr>
  </table>

<h2>Measured Function Calls</h2>
  <table>
  <tr><th>&nbsp;</th><th class="name">Name</th><th>Calls</th><th>Time</th><th><abbr title="Fraction of total simulation time">Fraction</abbr></th><th><abbr title="The maximum accumulated time of this action during a single time step">Max Time</abbr></th><th><abbr title="Deviation from average execution time">Deviation</abbr></th></tr>
  <xsl:for-each select="functions/function">
    <tr>
      <td><a href="{//simulation/modelinfo/prefix}_prof.{@id}.svg"><img class="thumb" src="{//simulation/modelinfo/prefix}_prof.{@id}.thumb.png" alt="Graph thumbnail" /></a></td>
      <td class="name"><a href="{info/@filename}#line={info/@startline}"><xsl:value-of select="name"/></a></td>
      <td><xsl:value-of select="ncall"/></td>
      <td><xsl:value-of select="time"/></td>
      <td><xsl:value-of select="format-number(100 * time div /simulation/modelinfo/totalTime,'##0.00')"/>%</td>
      <td><xsl:value-of select="maxTime"/></td>
      <td><xsl:value-of select="format-number((ncall * maxTime div time)-1,'##0.00')"/>x</td>
    </tr>
  </xsl:for-each>
  </table>

<h2>Measured Blocks</h2>
  <table>
  <tr><th>&nbsp;</th><th class="name">Name</th><th>Calls</th><th>Time</th><th><abbr title="Fraction of total simulation time">Fraction</abbr></th><th><abbr title="The maximum accumulated time of this action during a single time step">Max Time</abbr></th><th><abbr title="Deviation from average execution time">Deviation</abbr></th></tr>
  <xsl:for-each select="profileblocks/profileblock">
    <tr>
      <td><a href="{//simulation/modelinfo/prefix}_prof.{ref/@refid}.svg"><img class="thumb" src="{//simulation/modelinfo/prefix}_prof.{ref/@refid}.thumb.png" alt="Graph thumbnail" /></a></td>
      <td class="name"><a href="#{ref/@refid}"><xsl:value-of select="id(ref/@refid)/@name"/></a></td>
      <td><xsl:value-of select="ncall"/></td>
      <td><xsl:value-of select="time"/></td>
      <td><xsl:value-of select="format-number(100 * time div /simulation/modelinfo/totalTime,'##0.00')"/>%</td>
      <td><xsl:value-of select="maxTime"/></td>
      <td><xsl:value-of select="format-number((ncall * maxTime div time)-1,'##0.00')"/>x</td>
    </tr>
  </xsl:for-each>
  </table>

<h3>Equations</h3>
  <table>
  <tr><th class="name">Name</th><th>Variables</th></tr>
  <xsl:for-each select="equations/equation">
    <tr><td class="name"><a name="{@id}"><xsl:value-of select="@name"/></a></td>
    <td><xsl:choose>
      <xsl:when test="count(refs/ref)=0">&nbsp;</xsl:when>
      <xsl:otherwise><xsl:for-each select="refs/ref"><a href="#{@refid}"><xsl:value-of select="id(@refid)/@name"/></a><xsl:if test="position() != last()">, </xsl:if>
</xsl:for-each></xsl:otherwise>
    </xsl:choose></td>
    </tr>
  </xsl:for-each>
  </table>

<h3>Variables</h3>
  <table>
  <tr><th class="name">Name</th><th>Comment</th></tr>
  <xsl:for-each select="variables/variable">
    <tr>
    <td class="name"><a name="{@id}" href="{info/@filename}#line={info/@startline}"><xsl:value-of select="@name"/></a></td>
    <td><xsl:choose>
      <xsl:when test="string-length(@comment)=0">&nbsp;</xsl:when>
      <xsl:otherwise><xsl:value-of select="@comment"/></xsl:otherwise>
    </xsl:choose></td></tr>
  </xsl:for-each>
  </table>

<hr />
<p>
This report was generated by <a href="http://openmodelica.org">OpenModelica</a> on <xsl:value-of select="modelinfo/date"/>.
</p>

</body>

</html>

</xsl:template>

</xsl:stylesheet>
