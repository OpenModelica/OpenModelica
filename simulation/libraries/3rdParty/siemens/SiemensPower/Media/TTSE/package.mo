within SiemensPower.Media;
package TTSE "Water/steam table functions according to TTSE"


annotation(Documentation(
 info="<html>
<p>Direct functions (utilities) and Modelica Media for Water/steam table TTSE (latest version 2.4).</p>
<p><b>Important note:</b> Some libraries are needed and can be found in SiemensPower\\Utilities\\Libs. The libraries are: </p>
<p><ul>
<li>TTSEMoI.lib and TTSE.lib has to be copied to a library folder (for example Dymola 7.4\\bin\\lib). Another library directory can also be set by editing the file Dymola 7.4\\bin\\build.bat </li>
<li>TTSEDMoI.dll has to be copied to the SYSTEM32 folder of Windows or to the Dymola Work Directory.</li>
<li>TTSE.dll has to be copied to the SYSTEM32 folder of Windows or to the Dymola Work Directory.</li>
<li>IMPORTANT: TTSE doesn&apos;t need anymore to be initialized in Dymola. The initialization is done automatically one time during the first TTSE function call.</li>
</ul></p>
</html>",
    revisions="<html>
                      <ul>
                              <li> May 2011 by Julien Bonifay
                       </ul>
                        </html>"));
end TTSE;
