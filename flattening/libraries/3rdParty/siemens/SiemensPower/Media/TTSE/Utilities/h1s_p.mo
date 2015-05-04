within SiemensPower.Media.TTSE.Utilities;
function h1s_p "h1s(p)"
  import SI = Modelica.SIunits;
  input SI.Pressure p "Pressure";

  output SI.SpecificEnthalpy h1s "Bulb enthalpy";

  external "C" h1s= TTSE_h1s_p(p);

  annotation(Library={"TTSEmoI", "TTSE"},derivative=der_h1s_p, Documentation(info="<html>
<p>This function returns bulb enthalpy as function of p according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>internal </td>
                </tr>

           </table>
                Copyright &copy  2007 Siemens AG. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
        revisions="<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>"));

end h1s_p;
