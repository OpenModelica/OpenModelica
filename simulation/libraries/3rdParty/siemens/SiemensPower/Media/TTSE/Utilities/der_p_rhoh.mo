within SiemensPower.Media.TTSE.Utilities;
function der_p_rhoh "Time derivative of p(rho,h)"
  import SI = Modelica.SIunits;

 input SI.Density rho "Density";
 input SI.SpecificEnthalpy h "Specific enthalpy";
 input Real der_rho "Time derivative of the density";
 input Real der_h "Time derivative of the specific enthalpy";
 output Real der_p "Time derivative of the pressure";

algorithm
  der_p := SiemensPower.Media.TTSE.Utilities.p_rhoh_dh(rho, h)*der_h +
    SiemensPower.Media.TTSE.Utilities.p_rhoh_drho(rho, h)*der_rho;

annotation (
    Documentation(
 info="<HTML>
                    <p>This function returns the
                    time derivative of the pressure as function of rho and h
                  according to the chain rule. The partial derivatives are build with help of TTSE functions.
                    </p>
                   </HTML>

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
end der_p_rhoh;
