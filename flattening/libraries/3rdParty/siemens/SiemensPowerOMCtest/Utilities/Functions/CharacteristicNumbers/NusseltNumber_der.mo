within SiemensPowerOMCtest.Utilities.Functions.CharacteristicNumbers;
function NusseltNumber_der "time derivative of NusseltNumber"

  input Modelica.SIunits.CoefficientOfHeatTransfer alpha
    "Coefficient of heat transfer";
  input Modelica.SIunits.Length length "Characteristic length";
  input Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity";
  input Real alpha_der "time derivative of heat transfer coefficient";
  input Real length_der;
  input Real lambda_der "time derivative of the Thermal conductivity";
  output Real Nu_der "time derivat of the Nusselt number";

algorithm
//  Nu := alpha*length/lambda;
   Nu_der := alpha_der*length/lambda - lambda_der*alpha*length/lambda^2;
annotation (Documentation(
 info="<HTML>
                    <p>This function returns the time derivative of the Nusselt number.<br>
                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                   <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
    revisions="<html>
                      <ul>
                             <li> June 2007 by Haiko Steuer
                       </ul>
                        </html>"));
end NusseltNumber_der;
