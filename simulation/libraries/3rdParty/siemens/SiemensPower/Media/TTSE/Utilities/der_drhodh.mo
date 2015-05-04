within SiemensPower.Media.TTSE.Utilities;
function der_drhodh "Time derivative for drho_dh function"
  import SI = Modelica.SIunits;
  import SiemensPower;

   input SI.Pressure p "Pressure";
   input SI.SpecificEnthalpy h "Specific Enthalpy";
   input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
   input Real der_p "Time derivative of p";
   input Real der_h "Time derivative of h";
   output Real der_drdh "Time derivative of drho/dh";

algorithm
  der_drdh := SiemensPower.Media.TTSE.Utilities.rho_ph_d2h(p, h)*der_h +
    SiemensPower.Media.TTSE.Utilities.rho_ph_d2ph(p, h)*der_p;

annotation(Documentation(info="<html>
<p>This function returns the time derivative of drho/dh with the help of TTSE functions.
                    </p>
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
end der_drhodh;
