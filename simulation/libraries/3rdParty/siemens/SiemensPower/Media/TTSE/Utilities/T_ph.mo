within SiemensPower.Media.TTSE.Utilities;
function T_ph "T(p,h)"
  import SI = Modelica.SIunits;
  input SI.Pressure p "Pressure";
  input SI.SpecificEnthalpy h "Specific enthalpy";
  input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  output SI.Temperature T "Temperature";

  external "C" T= TTSE_T_ph(p,h,phase);

  annotation(Library={"TTSEmoI", "TTSE"},derivative(noDerivative=phase)=der_T_ph, Documentation(info="<html>
<p>This function returns the temperature as function of p and h. The water/steam functions are computed according to TTSE. </p>
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

end T_ph;
