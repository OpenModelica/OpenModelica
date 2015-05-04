within SiemensPower.Media.TTSE.Utilities;
function der_T_ph "Time derivative of T(p,h)"
  import SI = Modelica.SIunits;
    input SI.AbsolutePressure p "Pressure";
    input SI.SpecificEnthalpy h "Specific Enthalpy";
    input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    input Real der_p( unit = "Pa/s") "Time derivative of pressure";
    input Real der_h( unit = "J/(kg.s)") "Time derivative of specific enthalpy";
    output Real der_T(  unit = "K/s") "Time derivative of temperature";

algorithm
  der_T := SiemensPower.Media.TTSE.Utilities.T_ph_dh(p, h,phase)*der_h +
    SiemensPower.Media.TTSE.Utilities.T_ph_dp(p, h,phase)*der_p;

  annotation (Documentation(info="<html>
<p>This function returns the time derivative of the temperature as function of p and h according to the chain rule. The partial derivatives are build with help of TTSE functions. </p>
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
end der_T_ph;
