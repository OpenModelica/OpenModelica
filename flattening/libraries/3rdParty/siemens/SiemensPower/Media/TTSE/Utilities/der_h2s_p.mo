within SiemensPower.Media.TTSE.Utilities;
function der_h2s_p "Time derivative of h2s(p)"
  import SI = Modelica.SIunits;
    input SI.Pressure p "Pressure";
    input Real der_p "Time derivative of p";
    output Real der_h2s "Time derivative of dew enthalpy";

algorithm
  der_h2s := SiemensPower.Media.TTSE.Utilities.h2s_p_dp(p)*der_p;

  annotation (Documentation(info="<html>
<p>This function returns the time derivative of dew enthalpy with the help of TTSE functions. </p>
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
end der_h2s_p;
