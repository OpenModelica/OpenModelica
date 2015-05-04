within SiemensPower.Utilities.Functions.CharacteristicNumbers;
function NusseltNumber "Nusselt number"
  input Modelica.SIunits.CoefficientOfHeatTransfer alpha
    "Coefficient of heat transfer";
  input Modelica.SIunits.Length length "Characteristic length";
  input Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity";
  output Modelica.SIunits.NusseltNumber Nu "Nusselt number";
algorithm
  Nu := alpha*length/lambda;
  annotation (Documentation(info="Nusselt number Nu = alpha*length/lambda

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                            <td><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </td>
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
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>"),  derivative=NusseltNumber_der,
    Documentation(
 info="<HTML>
                    <p>This function returns the Nusselt number. It can be used to define the heat transfer coeficient alpha.<br>
                   </HTML>",
    revisions="<html>
                      <ul>
                             <li> June 2007 by Kilian Link
                       </ul>
                        </html>"));
end NusseltNumber;
