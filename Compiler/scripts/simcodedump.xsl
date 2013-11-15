<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:simcodedump="urn:simcodedump"
    extension-element-prefixes="simcodedump">

<xsl:template match="source">
  <xsl:value-of select="info/@file"/>:<xsl:value-of select="info/@lineStart"/>:<xsl:value-of select="info/@colStart"/>-<xsl:value-of select="info/@lineEnd"/>:<xsl:value-of select="info/@colEnd"/>
  <xsl:text> </xsl:text>
  <xsl:for-each select="type">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <xsl:value-of select="."/>
  </xsl:for-each>
</xsl:template>

<xsl:function name="simcodedump:escapeJS" as="xs:string">
  <xsl:param name="str" as="xs:string"/>
  <xsl:value-of select="replace(replace($str, '&quot;','\\&quot;'), '\n', '\\n')"/>
</xsl:function>

<xsl:template match="equation/assign">
  <h3 title="{@type}assignment index={../@index}"><script type="text/javascript">document.write(replaceSharedLiteral('<xsl:value-of select="simcodedump:escapeJS(defines/@name)"/> = <xsl:value-of select="simcodedump:escapeJS(rhs)"/>'));</script></h3>
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
  <xsl:value-of select="defines/@name"/> = <xsl:value-of select="rhs"/>
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
  <p>Solves for variables (<xsl:value-of select="count(defines)"/> variables, <xsl:value-of select="count(equation)"/> equations): <xsl:for-each select="defines">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <a href="#var_{@name}"><xsl:value-of select="@name"/></a>
  </xsl:for-each></p>
  <p>Equations <xsl:for-each select="eq"><a href="#eq_{@index}">#<xsl:value-of select="@index"/></a><xsl:text> </xsl:text></xsl:for-each></p>
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
  Solves for variables (<xsl:value-of select="count(defines)"/>): <xsl:for-each select="defines">
    <xsl:if test="not(position() = 1)">, </xsl:if>
    <a href="#var_{@name}"><xsl:value-of select="@name"/></a>
  </xsl:for-each>
  <table class="linear-matrix">
    <tr>
       <xsl:call-template name="linear-matrix">
         <xsl:with-param name="i" select="0"/>
         <xsl:with-param name="stop" select="count(defines)"/>
       </xsl:call-template>
    </tr>
  </table>
  <xsl:for-each select="matrix/cell">
    <p>Cell <xsl:value-of select="@row"/>,<xsl:value-of select="@col"/>: <xsl:apply-templates select="residual"/></p>
    <p><xsl:apply-templates select="source"/></p>
    <xsl:apply-templates select="operations/*"/>
  </xsl:for-each>
</xsl:template>

<xsl:template match="operations/substitution">
  <p><span title="substitution">Operation <xsl:number count="*" /> Substitution: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="before"/>','<xsl:value-of select="exp[last()]"/>');</script>
    <!-- <xsl:for-each select="exp">
      <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
      <xsl:value-of select="."/>
    </xsl:for-each> -->
  </p>
</xsl:template>

<xsl:template match="operations/dummyderivative">
  <p><span title="dummy derivative">Operation <xsl:number count="*" /> Dummyderivative: </span>
    <xsl:value-of select="chosen"/>
    <xsl:for-each select="candidate">
      <b class="arrow"><xsl:text disable-output-escaping="yes">&amp;rarr;</xsl:text></b>
      <xsl:value-of select="."/>
    </xsl:for-each>
  </p>
</xsl:template>

<xsl:template match="operations/simplify">
  <p><span title="simplify">Operation <xsl:number count="*" /> Simplify: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="before"/>','<xsl:value-of select="after"/>');</script>
  </p>
</xsl:template>

<xsl:template match="operations/inline">
  <p><span title="inline">Operation <xsl:number count="*" /> Inline: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="before"/>','<xsl:value-of select="after"/>');</script>
  </p>
</xsl:template>

<xsl:template match="operations/scalarize">
  <p><span title="inline">Operation <xsl:number count="*" /> Scalarize [<xsl:value-of select="@index"/>]: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="before"/>','<xsl:value-of select="after"/>');</script>
  </p>
</xsl:template>

<xsl:template match="operations/op-residual">
  <p><span title="make an equality equation into residual form">Operation <xsl:number count="*" /> Residual: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="defines/@name"/> = <xsl:value-of select="rhs"/>','0.0 = <xsl:value-of select="result"/>');</script>
  </p>
</xsl:template>

<xsl:template match="operations/solve">
  <p><span title="solve equation">Operation <xsl:number count="*" /> Solve: </span>
    <script type="text/javascript">show_diff('<xsl:value-of select="old/defines/@name"/> = <xsl:value-of select="old/rhs"/>','<xsl:value-of select="new/defines/@name"/> = <xsl:value-of select="new/rhs"/>');</script>
    <xsl:if test="assertions/assertion">assertion...</xsl:if></p>
</xsl:template>

<xsl:template match="operations/solved">
  <p><span title="already solved equation">Operation <xsl:number count="*" /> Solved: </span>
    <xsl:value-of select="defines/@name"/><xsl:text> = </xsl:text><xsl:value-of select="rhs"/>
  </p>
</xsl:template>

<xsl:template match="operations/linear-solved">
  <p><span title="solved known linear system of equations">Operation <xsl:number count="*" /> Linear-solved: </span>
    TODO: Fix this crap: <xsl:value-of select="."/>
  </p>
</xsl:template>

<xsl:template match="operations/derivative">
  <p><span title="solve">Operation <xsl:number count="*" /> d/dx: </span>
   d/d<xsl:value-of select="with-respect-to"/><xsl:text> </xsl:text>
   <script type="text/javascript">show_diff('<xsl:value-of select="exp"/>','<xsl:value-of select="result"/>');</script>
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
<script type="text/javascript">
/**
 * Diff Match and Patch
 *
 * Copyright 2006 Google Inc.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
(function(){function diff_match_patch(){this.Diff_Timeout=1;this.Diff_EditCost=4;this.Match_Threshold=0.5;this.Match_Distance=1E3;this.Patch_DeleteThreshold=0.5;this.Patch_Margin=4;this.Match_MaxBits=32}
diff_match_patch.prototype.diff_main=function(a,b,c,d){&quot;undefined&quot;==typeof d&amp;&amp;(d=0&gt;=this.Diff_Timeout?Number.MAX_VALUE:(new Date).getTime()+1E3*this.Diff_Timeout);if(null==a||null==b)throw Error(&quot;Null input. (diff_main)&quot;);if(a==b)return a?[[0,a]]:[];&quot;undefined&quot;==typeof c&amp;&amp;(c=!0);var e=c,f=this.diff_commonPrefix(a,b);c=a.substring(0,f);a=a.substring(f);b=b.substring(f);var f=this.diff_commonSuffix(a,b),g=a.substring(a.length-f);a=a.substring(0,a.length-f);b=b.substring(0,b.length-f);a=this.diff_compute_(a,
b,e,d);c&amp;&amp;a.unshift([0,c]);g&amp;&amp;a.push([0,g]);this.diff_cleanupMerge(a);return a};
diff_match_patch.prototype.diff_compute_=function(a,b,c,d){if(!a)return[[1,b]];if(!b)return[[-1,a]];var e=a.length&gt;b.length?a:b,f=a.length&gt;b.length?b:a,g=e.indexOf(f);return-1!=g?(c=[[1,e.substring(0,g)],[0,f],[1,e.substring(g+f.length)]],a.length&gt;b.length&amp;&amp;(c[0][0]=c[2][0]=-1),c):1==f.length?[[-1,a],[1,b]]:(e=this.diff_halfMatch_(a,b))?(f=e[0],a=e[1],g=e[2],b=e[3],e=e[4],f=this.diff_main(f,g,c,d),c=this.diff_main(a,b,c,d),f.concat([[0,e]],c)):c&amp;&amp;100&lt;a.length&amp;&amp;100&lt;b.length?this.diff_lineMode_(a,b,
d):this.diff_bisect_(a,b,d)};
diff_match_patch.prototype.diff_lineMode_=function(a,b,c){var d=this.diff_linesToChars_(a,b);a=d.chars1;b=d.chars2;d=d.lineArray;a=this.diff_main(a,b,!1,c);this.diff_charsToLines_(a,d);this.diff_cleanupSemantic(a);a.push([0,&quot;&quot;]);for(var e=d=b=0,f=&quot;&quot;,g=&quot;&quot;;b&lt;a.length;){switch(a[b][0]){case 1:e++;g+=a[b][1];break;case -1:d++;f+=a[b][1];break;case 0:if(1&lt;=d&amp;&amp;1&lt;=e){a.splice(b-d-e,d+e);b=b-d-e;d=this.diff_main(f,g,!1,c);for(e=d.length-1;0&lt;=e;e--)a.splice(b,0,d[e]);b+=d.length}d=e=0;g=f=&quot;&quot;}b++}a.pop();return a};
diff_match_patch.prototype.diff_bisect_=function(a,b,c){for(var d=a.length,e=b.length,f=Math.ceil((d+e)/2),g=f,h=2*f,j=Array(h),i=Array(h),k=0;k&lt;h;k++)j[k]=-1,i[k]=-1;j[g+1]=0;i[g+1]=0;for(var k=d-e,q=0!=k%2,r=0,t=0,p=0,w=0,v=0;v&lt;f&amp;&amp;!((new Date).getTime()&gt;c);v++){for(var n=-v+r;n&lt;=v-t;n+=2){var l=g+n,m;m=n==-v||n!=v&amp;&amp;j[l-1]&lt;j[l+1]?j[l+1]:j[l-1]+1;for(var s=m-n;m&lt;d&amp;&amp;s&lt;e&amp;&amp;a.charAt(m)==b.charAt(s);)m++,s++;j[l]=m;if(m&gt;d)t+=2;else if(s&gt;e)r+=2;else if(q&amp;&amp;(l=g+k-n,0&lt;=l&amp;&amp;l&lt;h&amp;&amp;-1!=i[l])){var u=d-i[l];if(m&gt;=
u)return this.diff_bisectSplit_(a,b,m,s,c)}}for(n=-v+p;n&lt;=v-w;n+=2){l=g+n;u=n==-v||n!=v&amp;&amp;i[l-1]&lt;i[l+1]?i[l+1]:i[l-1]+1;for(m=u-n;u&lt;d&amp;&amp;m&lt;e&amp;&amp;a.charAt(d-u-1)==b.charAt(e-m-1);)u++,m++;i[l]=u;if(u&gt;d)w+=2;else if(m&gt;e)p+=2;else if(!q&amp;&amp;(l=g+k-n,0&lt;=l&amp;&amp;(l&lt;h&amp;&amp;-1!=j[l])&amp;&amp;(m=j[l],s=g+m-l,u=d-u,m&gt;=u)))return this.diff_bisectSplit_(a,b,m,s,c)}}return[[-1,a],[1,b]]};
diff_match_patch.prototype.diff_bisectSplit_=function(a,b,c,d,e){var f=a.substring(0,c),g=b.substring(0,d);a=a.substring(c);b=b.substring(d);f=this.diff_main(f,g,!1,e);e=this.diff_main(a,b,!1,e);return f.concat(e)};
diff_match_patch.prototype.diff_linesToChars_=function(a,b){function c(a){for(var b=&quot;&quot;,c=0,f=-1,g=d.length;f&lt;a.length-1;){f=a.indexOf(&quot;\n&quot;,c);-1==f&amp;&amp;(f=a.length-1);var r=a.substring(c,f+1),c=f+1;(e.hasOwnProperty?e.hasOwnProperty(r):void 0!==e[r])?b+=String.fromCharCode(e[r]):(b+=String.fromCharCode(g),e[r]=g,d[g++]=r)}return b}var d=[],e={};d[0]=&quot;&quot;;var f=c(a),g=c(b);return{chars1:f,chars2:g,lineArray:d}};
diff_match_patch.prototype.diff_charsToLines_=function(a,b){for(var c=0;c&lt;a.length;c++){for(var d=a[c][1],e=[],f=0;f&lt;d.length;f++)e[f]=b[d.charCodeAt(f)];a[c][1]=e.join(&quot;&quot;)}};diff_match_patch.prototype.diff_commonPrefix=function(a,b){if(!a||!b||a.charAt(0)!=b.charAt(0))return 0;for(var c=0,d=Math.min(a.length,b.length),e=d,f=0;c&lt;e;)a.substring(f,e)==b.substring(f,e)?f=c=e:d=e,e=Math.floor((d-c)/2+c);return e};
diff_match_patch.prototype.diff_commonSuffix=function(a,b){if(!a||!b||a.charAt(a.length-1)!=b.charAt(b.length-1))return 0;for(var c=0,d=Math.min(a.length,b.length),e=d,f=0;c&lt;e;)a.substring(a.length-e,a.length-f)==b.substring(b.length-e,b.length-f)?f=c=e:d=e,e=Math.floor((d-c)/2+c);return e};
diff_match_patch.prototype.diff_commonOverlap_=function(a,b){var c=a.length,d=b.length;if(0==c||0==d)return 0;c&gt;d?a=a.substring(c-d):c&lt;d&amp;&amp;(b=b.substring(0,c));c=Math.min(c,d);if(a==b)return c;for(var d=0,e=1;;){var f=a.substring(c-e),f=b.indexOf(f);if(-1==f)return d;e+=f;if(0==f||a.substring(c-e)==b.substring(0,e))d=e,e++}};
diff_match_patch.prototype.diff_halfMatch_=function(a,b){function c(a,b,c){for(var d=a.substring(c,c+Math.floor(a.length/4)),e=-1,g=&quot;&quot;,h,j,n,l;-1!=(e=b.indexOf(d,e+1));){var m=f.diff_commonPrefix(a.substring(c),b.substring(e)),s=f.diff_commonSuffix(a.substring(0,c),b.substring(0,e));g.length&lt;s+m&amp;&amp;(g=b.substring(e-s,e)+b.substring(e,e+m),h=a.substring(0,c-s),j=a.substring(c+m),n=b.substring(0,e-s),l=b.substring(e+m))}return 2*g.length&gt;=a.length?[h,j,n,l,g]:null}if(0&gt;=this.Diff_Timeout)return null;
var d=a.length&gt;b.length?a:b,e=a.length&gt;b.length?b:a;if(4&gt;d.length||2*e.length&lt;d.length)return null;var f=this,g=c(d,e,Math.ceil(d.length/4)),d=c(d,e,Math.ceil(d.length/2)),h;if(!g&amp;&amp;!d)return null;h=d?g?g[4].length&gt;d[4].length?g:d:d:g;var j;a.length&gt;b.length?(g=h[0],d=h[1],e=h[2],j=h[3]):(e=h[0],j=h[1],g=h[2],d=h[3]);h=h[4];return[g,d,e,j,h]};
diff_match_patch.prototype.diff_cleanupSemantic=function(a){for(var b=!1,c=[],d=0,e=null,f=0,g=0,h=0,j=0,i=0;f&lt;a.length;)0==a[f][0]?(c[d++]=f,g=j,h=i,i=j=0,e=a[f][1]):(1==a[f][0]?j+=a[f][1].length:i+=a[f][1].length,e&amp;&amp;(e.length&lt;=Math.max(g,h)&amp;&amp;e.length&lt;=Math.max(j,i))&amp;&amp;(a.splice(c[d-1],0,[-1,e]),a[c[d-1]+1][0]=1,d--,d--,f=0&lt;d?c[d-1]:-1,i=j=h=g=0,e=null,b=!0)),f++;b&amp;&amp;this.diff_cleanupMerge(a);this.diff_cleanupSemanticLossless(a);for(f=1;f&lt;a.length;){if(-1==a[f-1][0]&amp;&amp;1==a[f][0]){b=a[f-1][1];c=a[f][1];
d=this.diff_commonOverlap_(b,c);e=this.diff_commonOverlap_(c,b);if(d&gt;=e){if(d&gt;=b.length/2||d&gt;=c.length/2)a.splice(f,0,[0,c.substring(0,d)]),a[f-1][1]=b.substring(0,b.length-d),a[f+1][1]=c.substring(d),f++}else if(e&gt;=b.length/2||e&gt;=c.length/2)a.splice(f,0,[0,b.substring(0,e)]),a[f-1][0]=1,a[f-1][1]=c.substring(0,c.length-e),a[f+1][0]=-1,a[f+1][1]=b.substring(e),f++;f++}f++}};
diff_match_patch.prototype.diff_cleanupSemanticLossless=function(a){function b(a,b){if(!a||!b)return 6;var c=a.charAt(a.length-1),d=b.charAt(0),e=c.match(diff_match_patch.nonAlphaNumericRegex_),f=d.match(diff_match_patch.nonAlphaNumericRegex_),g=e&amp;&amp;c.match(diff_match_patch.whitespaceRegex_),h=f&amp;&amp;d.match(diff_match_patch.whitespaceRegex_),c=g&amp;&amp;c.match(diff_match_patch.linebreakRegex_),d=h&amp;&amp;d.match(diff_match_patch.linebreakRegex_),i=c&amp;&amp;a.match(diff_match_patch.blanklineEndRegex_),j=d&amp;&amp;b.match(diff_match_patch.blanklineStartRegex_);
return i||j?5:c||d?4:e&amp;&amp;!g&amp;&amp;h?3:g||h?2:e||f?1:0}for(var c=1;c&lt;a.length-1;){if(0==a[c-1][0]&amp;&amp;0==a[c+1][0]){var d=a[c-1][1],e=a[c][1],f=a[c+1][1],g=this.diff_commonSuffix(d,e);if(g)var h=e.substring(e.length-g),d=d.substring(0,d.length-g),e=h+e.substring(0,e.length-g),f=h+f;for(var g=d,h=e,j=f,i=b(d,e)+b(e,f);e.charAt(0)===f.charAt(0);){var d=d+e.charAt(0),e=e.substring(1)+f.charAt(0),f=f.substring(1),k=b(d,e)+b(e,f);k&gt;=i&amp;&amp;(i=k,g=d,h=e,j=f)}a[c-1][1]!=g&amp;&amp;(g?a[c-1][1]=g:(a.splice(c-1,1),c--),a[c][1]=
h,j?a[c+1][1]=j:(a.splice(c+1,1),c--))}c++}};diff_match_patch.nonAlphaNumericRegex_=/[^a-zA-Z0-9]/;diff_match_patch.whitespaceRegex_=/\s/;diff_match_patch.linebreakRegex_=/[\r\n]/;diff_match_patch.blanklineEndRegex_=/\n\r?\n$/;diff_match_patch.blanklineStartRegex_=/^\r?\n\r?\n/;
diff_match_patch.prototype.diff_cleanupEfficiency=function(a){for(var b=!1,c=[],d=0,e=null,f=0,g=!1,h=!1,j=!1,i=!1;f&lt;a.length;){if(0==a[f][0])a[f][1].length&lt;this.Diff_EditCost&amp;&amp;(j||i)?(c[d++]=f,g=j,h=i,e=a[f][1]):(d=0,e=null),j=i=!1;else if(-1==a[f][0]?i=!0:j=!0,e&amp;&amp;(g&amp;&amp;h&amp;&amp;j&amp;&amp;i||e.length&lt;this.Diff_EditCost/2&amp;&amp;3==g+h+j+i))a.splice(c[d-1],0,[-1,e]),a[c[d-1]+1][0]=1,d--,e=null,g&amp;&amp;h?(j=i=!0,d=0):(d--,f=0&lt;d?c[d-1]:-1,j=i=!1),b=!0;f++}b&amp;&amp;this.diff_cleanupMerge(a)};
diff_match_patch.prototype.diff_cleanupMerge=function(a){a.push([0,&quot;&quot;]);for(var b=0,c=0,d=0,e=&quot;&quot;,f=&quot;&quot;,g;b&lt;a.length;)switch(a[b][0]){case 1:d++;f+=a[b][1];b++;break;case -1:c++;e+=a[b][1];b++;break;case 0:1&lt;c+d?(0!==c&amp;&amp;0!==d&amp;&amp;(g=this.diff_commonPrefix(f,e),0!==g&amp;&amp;(0&lt;b-c-d&amp;&amp;0==a[b-c-d-1][0]?a[b-c-d-1][1]+=f.substring(0,g):(a.splice(0,0,[0,f.substring(0,g)]),b++),f=f.substring(g),e=e.substring(g)),g=this.diff_commonSuffix(f,e),0!==g&amp;&amp;(a[b][1]=f.substring(f.length-g)+a[b][1],f=f.substring(0,f.length-
g),e=e.substring(0,e.length-g))),0===c?a.splice(b-d,c+d,[1,f]):0===d?a.splice(b-c,c+d,[-1,e]):a.splice(b-c-d,c+d,[-1,e],[1,f]),b=b-c-d+(c?1:0)+(d?1:0)+1):0!==b&amp;&amp;0==a[b-1][0]?(a[b-1][1]+=a[b][1],a.splice(b,1)):b++,c=d=0,f=e=&quot;&quot;}&quot;&quot;===a[a.length-1][1]&amp;&amp;a.pop();c=!1;for(b=1;b&lt;a.length-1;)0==a[b-1][0]&amp;&amp;0==a[b+1][0]&amp;&amp;(a[b][1].substring(a[b][1].length-a[b-1][1].length)==a[b-1][1]?(a[b][1]=a[b-1][1]+a[b][1].substring(0,a[b][1].length-a[b-1][1].length),a[b+1][1]=a[b-1][1]+a[b+1][1],a.splice(b-1,1),c=!0):a[b][1].substring(0,
a[b+1][1].length)==a[b+1][1]&amp;&amp;(a[b-1][1]+=a[b+1][1],a[b][1]=a[b][1].substring(a[b+1][1].length)+a[b+1][1],a.splice(b+1,1),c=!0)),b++;c&amp;&amp;this.diff_cleanupMerge(a)};diff_match_patch.prototype.diff_xIndex=function(a,b){var c=0,d=0,e=0,f=0,g;for(g=0;g&lt;a.length;g++){1!==a[g][0]&amp;&amp;(c+=a[g][1].length);-1!==a[g][0]&amp;&amp;(d+=a[g][1].length);if(c&gt;b)break;e=c;f=d}return a.length!=g&amp;&amp;-1===a[g][0]?f:f+(b-e)};
diff_match_patch.prototype.diff_prettyHtml=function(a){for(var b=[],c=/&amp;/g,d=/&lt;/g,e=/&gt;/g,f=/\n/g,g=0;g&lt;a.length;g++){var h=a[g][0],j=a[g][1],j=j.replace(c,&quot;&amp;amp;&quot;).replace(d,&quot;&amp;lt;&quot;).replace(e,&quot;&amp;gt;&quot;).replace(f,&quot;&amp;para;&lt;br&gt;&quot;);switch(h){case 1:b[g]=&apos;&lt;ins style=&quot;background:#e6ffe6;&quot;&gt;&apos;+j+&quot;&lt;/ins&gt;&quot;;break;case -1:b[g]=&apos;&lt;del style=&quot;background:#ffe6e6;&quot;&gt;&apos;+j+&quot;&lt;/del&gt;&quot;;break;case 0:b[g]=&quot;&lt;span&gt;&quot;+j+&quot;&lt;/span&gt;&quot;}}return b.join(&quot;&quot;)};
diff_match_patch.prototype.diff_text1=function(a){for(var b=[],c=0;c&lt;a.length;c++)1!==a[c][0]&amp;&amp;(b[c]=a[c][1]);return b.join(&quot;&quot;)};diff_match_patch.prototype.diff_text2=function(a){for(var b=[],c=0;c&lt;a.length;c++)-1!==a[c][0]&amp;&amp;(b[c]=a[c][1]);return b.join(&quot;&quot;)};diff_match_patch.prototype.diff_levenshtein=function(a){for(var b=0,c=0,d=0,e=0;e&lt;a.length;e++){var f=a[e][0],g=a[e][1];switch(f){case 1:c+=g.length;break;case -1:d+=g.length;break;case 0:b+=Math.max(c,d),d=c=0}}return b+=Math.max(c,d)};
diff_match_patch.prototype.diff_toDelta=function(a){for(var b=[],c=0;c&lt;a.length;c++)switch(a[c][0]){case 1:b[c]=&quot;+&quot;+encodeURI(a[c][1]);break;case -1:b[c]=&quot;-&quot;+a[c][1].length;break;case 0:b[c]=&quot;=&quot;+a[c][1].length}return b.join(&quot;\t&quot;).replace(/%20/g,&quot; &quot;)};
diff_match_patch.prototype.diff_fromDelta=function(a,b){for(var c=[],d=0,e=0,f=b.split(/\t/g),g=0;g&lt;f.length;g++){var h=f[g].substring(1);switch(f[g].charAt(0)){case &quot;+&quot;:try{c[d++]=[1,decodeURI(h)]}catch(j){throw Error(&quot;Illegal escape in diff_fromDelta: &quot;+h);}break;case &quot;-&quot;:case &quot;=&quot;:var i=parseInt(h,10);if(isNaN(i)||0&gt;i)throw Error(&quot;Invalid number in diff_fromDelta: &quot;+h);h=a.substring(e,e+=i);&quot;=&quot;==f[g].charAt(0)?c[d++]=[0,h]:c[d++]=[-1,h];break;default:if(f[g])throw Error(&quot;Invalid diff operation in diff_fromDelta: &quot;+
f[g]);}}if(e!=a.length)throw Error(&quot;Delta length (&quot;+e+&quot;) does not equal source text length (&quot;+a.length+&quot;).&quot;);return c};diff_match_patch.prototype.match_main=function(a,b,c){if(null==a||null==b||null==c)throw Error(&quot;Null input. (match_main)&quot;);c=Math.max(0,Math.min(c,a.length));return a==b?0:a.length?a.substring(c,c+b.length)==b?c:this.match_bitap_(a,b,c):-1};
diff_match_patch.prototype.match_bitap_=function(a,b,c){function d(a,d){var e=a/b.length,g=Math.abs(c-d);return!f.Match_Distance?g?1:e:e+g/f.Match_Distance}if(b.length&gt;this.Match_MaxBits)throw Error(&quot;Pattern too long for this browser.&quot;);var e=this.match_alphabet_(b),f=this,g=this.Match_Threshold,h=a.indexOf(b,c);-1!=h&amp;&amp;(g=Math.min(d(0,h),g),h=a.lastIndexOf(b,c+b.length),-1!=h&amp;&amp;(g=Math.min(d(0,h),g)));for(var j=1&lt;&lt;b.length-1,h=-1,i,k,q=b.length+a.length,r,t=0;t&lt;b.length;t++){i=0;for(k=q;i&lt;k;)d(t,c+
k)&lt;=g?i=k:q=k,k=Math.floor((q-i)/2+i);q=k;i=Math.max(1,c-k+1);var p=Math.min(c+k,a.length)+b.length;k=Array(p+2);for(k[p+1]=(1&lt;&lt;t)-1;p&gt;=i;p--){var w=e[a.charAt(p-1)];k[p]=0===t?(k[p+1]&lt;&lt;1|1)&amp;w:(k[p+1]&lt;&lt;1|1)&amp;w|((r[p+1]|r[p])&lt;&lt;1|1)|r[p+1];if(k[p]&amp;j&amp;&amp;(w=d(t,p-1),w&lt;=g))if(g=w,h=p-1,h&gt;c)i=Math.max(1,2*c-h);else break}if(d(t+1,c)&gt;g)break;r=k}return h};
diff_match_patch.prototype.match_alphabet_=function(a){for(var b={},c=0;c&lt;a.length;c++)b[a.charAt(c)]=0;for(c=0;c&lt;a.length;c++)b[a.charAt(c)]|=1&lt;&lt;a.length-c-1;return b};
diff_match_patch.prototype.patch_addContext_=function(a,b){if(0!=b.length){for(var c=b.substring(a.start2,a.start2+a.length1),d=0;b.indexOf(c)!=b.lastIndexOf(c)&amp;&amp;c.length&lt;this.Match_MaxBits-this.Patch_Margin-this.Patch_Margin;)d+=this.Patch_Margin,c=b.substring(a.start2-d,a.start2+a.length1+d);d+=this.Patch_Margin;(c=b.substring(a.start2-d,a.start2))&amp;&amp;a.diffs.unshift([0,c]);(d=b.substring(a.start2+a.length1,a.start2+a.length1+d))&amp;&amp;a.diffs.push([0,d]);a.start1-=c.length;a.start2-=c.length;a.length1+=
c.length+d.length;a.length2+=c.length+d.length}};
diff_match_patch.prototype.patch_make=function(a,b,c){var d;if(&quot;string&quot;==typeof a&amp;&amp;&quot;string&quot;==typeof b&amp;&amp;&quot;undefined&quot;==typeof c)d=a,b=this.diff_main(d,b,!0),2&lt;b.length&amp;&amp;(this.diff_cleanupSemantic(b),this.diff_cleanupEfficiency(b));else if(a&amp;&amp;&quot;object&quot;==typeof a&amp;&amp;&quot;undefined&quot;==typeof b&amp;&amp;&quot;undefined&quot;==typeof c)b=a,d=this.diff_text1(b);else if(&quot;string&quot;==typeof a&amp;&amp;b&amp;&amp;&quot;object&quot;==typeof b&amp;&amp;&quot;undefined&quot;==typeof c)d=a;else if(&quot;string&quot;==typeof a&amp;&amp;&quot;string&quot;==typeof b&amp;&amp;c&amp;&amp;&quot;object&quot;==typeof c)d=a,b=c;else throw Error(&quot;Unknown call format to patch_make.&quot;);
if(0===b.length)return[];c=[];a=new diff_match_patch.patch_obj;for(var e=0,f=0,g=0,h=d,j=0;j&lt;b.length;j++){var i=b[j][0],k=b[j][1];!e&amp;&amp;0!==i&amp;&amp;(a.start1=f,a.start2=g);switch(i){case 1:a.diffs[e++]=b[j];a.length2+=k.length;d=d.substring(0,g)+k+d.substring(g);break;case -1:a.length1+=k.length;a.diffs[e++]=b[j];d=d.substring(0,g)+d.substring(g+k.length);break;case 0:k.length&lt;=2*this.Patch_Margin&amp;&amp;e&amp;&amp;b.length!=j+1?(a.diffs[e++]=b[j],a.length1+=k.length,a.length2+=k.length):k.length&gt;=2*this.Patch_Margin&amp;&amp;
e&amp;&amp;(this.patch_addContext_(a,h),c.push(a),a=new diff_match_patch.patch_obj,e=0,h=d,f=g)}1!==i&amp;&amp;(f+=k.length);-1!==i&amp;&amp;(g+=k.length)}e&amp;&amp;(this.patch_addContext_(a,h),c.push(a));return c};diff_match_patch.prototype.patch_deepCopy=function(a){for(var b=[],c=0;c&lt;a.length;c++){var d=a[c],e=new diff_match_patch.patch_obj;e.diffs=[];for(var f=0;f&lt;d.diffs.length;f++)e.diffs[f]=d.diffs[f].slice();e.start1=d.start1;e.start2=d.start2;e.length1=d.length1;e.length2=d.length2;b[c]=e}return b};
diff_match_patch.prototype.patch_apply=function(a,b){if(0==a.length)return[b,[]];a=this.patch_deepCopy(a);var c=this.patch_addPadding(a);b=c+b+c;this.patch_splitMax(a);for(var d=0,e=[],f=0;f&lt;a.length;f++){var g=a[f].start2+d,h=this.diff_text1(a[f].diffs),j,i=-1;if(h.length&gt;this.Match_MaxBits){if(j=this.match_main(b,h.substring(0,this.Match_MaxBits),g),-1!=j&amp;&amp;(i=this.match_main(b,h.substring(h.length-this.Match_MaxBits),g+h.length-this.Match_MaxBits),-1==i||j&gt;=i))j=-1}else j=this.match_main(b,h,g);
if(-1==j)e[f]=!1,d-=a[f].length2-a[f].length1;else if(e[f]=!0,d=j-g,g=-1==i?b.substring(j,j+h.length):b.substring(j,i+this.Match_MaxBits),h==g)b=b.substring(0,j)+this.diff_text2(a[f].diffs)+b.substring(j+h.length);else if(g=this.diff_main(h,g,!1),h.length&gt;this.Match_MaxBits&amp;&amp;this.diff_levenshtein(g)/h.length&gt;this.Patch_DeleteThreshold)e[f]=!1;else{this.diff_cleanupSemanticLossless(g);for(var h=0,k,i=0;i&lt;a[f].diffs.length;i++){var q=a[f].diffs[i];0!==q[0]&amp;&amp;(k=this.diff_xIndex(g,h));1===q[0]?b=b.substring(0,
j+k)+q[1]+b.substring(j+k):-1===q[0]&amp;&amp;(b=b.substring(0,j+k)+b.substring(j+this.diff_xIndex(g,h+q[1].length)));-1!==q[0]&amp;&amp;(h+=q[1].length)}}}b=b.substring(c.length,b.length-c.length);return[b,e]};
diff_match_patch.prototype.patch_addPadding=function(a){for(var b=this.Patch_Margin,c=&quot;&quot;,d=1;d&lt;=b;d++)c+=String.fromCharCode(d);for(d=0;d&lt;a.length;d++)a[d].start1+=b,a[d].start2+=b;var d=a[0],e=d.diffs;if(0==e.length||0!=e[0][0])e.unshift([0,c]),d.start1-=b,d.start2-=b,d.length1+=b,d.length2+=b;else if(b&gt;e[0][1].length){var f=b-e[0][1].length;e[0][1]=c.substring(e[0][1].length)+e[0][1];d.start1-=f;d.start2-=f;d.length1+=f;d.length2+=f}d=a[a.length-1];e=d.diffs;0==e.length||0!=e[e.length-1][0]?(e.push([0,
c]),d.length1+=b,d.length2+=b):b&gt;e[e.length-1][1].length&amp;&amp;(f=b-e[e.length-1][1].length,e[e.length-1][1]+=c.substring(0,f),d.length1+=f,d.length2+=f);return c};
diff_match_patch.prototype.patch_splitMax=function(a){for(var b=this.Match_MaxBits,c=0;c&lt;a.length;c++)if(!(a[c].length1&lt;=b)){var d=a[c];a.splice(c--,1);for(var e=d.start1,f=d.start2,g=&quot;&quot;;0!==d.diffs.length;){var h=new diff_match_patch.patch_obj,j=!0;h.start1=e-g.length;h.start2=f-g.length;&quot;&quot;!==g&amp;&amp;(h.length1=h.length2=g.length,h.diffs.push([0,g]));for(;0!==d.diffs.length&amp;&amp;h.length1&lt;b-this.Patch_Margin;){var g=d.diffs[0][0],i=d.diffs[0][1];1===g?(h.length2+=i.length,f+=i.length,h.diffs.push(d.diffs.shift()),
j=!1):-1===g&amp;&amp;1==h.diffs.length&amp;&amp;0==h.diffs[0][0]&amp;&amp;i.length&gt;2*b?(h.length1+=i.length,e+=i.length,j=!1,h.diffs.push([g,i]),d.diffs.shift()):(i=i.substring(0,b-h.length1-this.Patch_Margin),h.length1+=i.length,e+=i.length,0===g?(h.length2+=i.length,f+=i.length):j=!1,h.diffs.push([g,i]),i==d.diffs[0][1]?d.diffs.shift():d.diffs[0][1]=d.diffs[0][1].substring(i.length))}g=this.diff_text2(h.diffs);g=g.substring(g.length-this.Patch_Margin);i=this.diff_text1(d.diffs).substring(0,this.Patch_Margin);&quot;&quot;!==i&amp;&amp;
(h.length1+=i.length,h.length2+=i.length,0!==h.diffs.length&amp;&amp;0===h.diffs[h.diffs.length-1][0]?h.diffs[h.diffs.length-1][1]+=i:h.diffs.push([0,i]));j||a.splice(++c,0,h)}}};diff_match_patch.prototype.patch_toText=function(a){for(var b=[],c=0;c&lt;a.length;c++)b[c]=a[c];return b.join(&quot;&quot;)};
diff_match_patch.prototype.patch_fromText=function(a){var b=[];if(!a)return b;a=a.split(&quot;\n&quot;);for(var c=0,d=/^@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@$/;c&lt;a.length;){var e=a[c].match(d);if(!e)throw Error(&quot;Invalid patch string: &quot;+a[c]);var f=new diff_match_patch.patch_obj;b.push(f);f.start1=parseInt(e[1],10);&quot;&quot;===e[2]?(f.start1--,f.length1=1):&quot;0&quot;==e[2]?f.length1=0:(f.start1--,f.length1=parseInt(e[2],10));f.start2=parseInt(e[3],10);&quot;&quot;===e[4]?(f.start2--,f.length2=1):&quot;0&quot;==e[4]?f.length2=0:(f.start2--,f.length2=
parseInt(e[4],10));for(c++;c&lt;a.length;){e=a[c].charAt(0);try{var g=decodeURI(a[c].substring(1))}catch(h){throw Error(&quot;Illegal escape in patch_fromText: &quot;+g);}if(&quot;-&quot;==e)f.diffs.push([-1,g]);else if(&quot;+&quot;==e)f.diffs.push([1,g]);else if(&quot; &quot;==e)f.diffs.push([0,g]);else if(&quot;@&quot;==e)break;else if(&quot;&quot;!==e)throw Error(&apos;Invalid patch mode &quot;&apos;+e+&apos;&quot; in: &apos;+g);c++}}return b};diff_match_patch.patch_obj=function(){this.diffs=[];this.start2=this.start1=null;this.length2=this.length1=0};
diff_match_patch.patch_obj.prototype.toString=function(){var a,b;a=0===this.length1?this.start1+&quot;,0&quot;:1==this.length1?this.start1+1:this.start1+1+&quot;,&quot;+this.length1;b=0===this.length2?this.start2+&quot;,0&quot;:1==this.length2?this.start2+1:this.start2+1+&quot;,&quot;+this.length2;a=[&quot;@@ -&quot;+a+&quot; +&quot;+b+&quot; @@\n&quot;];var c;for(b=0;b&lt;this.diffs.length;b++){switch(this.diffs[b][0]){case 1:c=&quot;+&quot;;break;case -1:c=&quot;-&quot;;break;case 0:c=&quot; &quot;}a[b+1]=c+encodeURI(this.diffs[b][1])+&quot;\n&quot;}return a.join(&quot;&quot;).replace(/%20/g,&quot; &quot;)};
this.diff_match_patch=diff_match_patch;this.DIFF_DELETE=-1;this.DIFF_INSERT=1;this.DIFF_EQUAL=0;})()
</script>
  <script type="text/javascript">
    var dmp = new diff_match_patch();
    dmp.Diff_EditCost = 4;
    var literals = [
      <xsl:for-each select="simcodedump/literals/exp">
        "<xsl:value-of select="simcodedump:escapeJS(.)"/>",
      </xsl:for-each>
    ];
    function replaceSharedLiteral(str) {
      var re = /#SHARED_LITERAL_([0-9]*).*#/;
      var match = str.match(re);
      if (match) {
        var ix = parseInt(match[1]);
        var lit = '&lt;a href="#literal_' + match[1] + '">' + literals[ix-1] + '&lt;/a>';
        str = replaceSharedLiteral(str.replace(re,lit));
      }
      return str;
    }
    function show_diff(before,after) {
      var diffs = dmp.diff_main(before, after, false);
      dmp.diff_cleanupEfficiency(diffs);
      var html = dmp.diff_prettyHtml(diffs);
      document.write(html);
    }
  </script>
  </head>
  <body>
  <noscript>This html-page requires javascript to function correctly.</noscript>
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
  <h2>Shared literals</h2>
  <script type="text/javascript">
    for (var i = 1; i &lt;= literals.length ; i++) {
      document.write('<p>&lt;a name="literal_' + i + '">' + i + '&lt;/a>: ' + literals[i-1] + '</p>');
    }
  </script>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>
