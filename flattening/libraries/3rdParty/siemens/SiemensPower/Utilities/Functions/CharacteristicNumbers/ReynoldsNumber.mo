within SiemensPower.Utilities.Functions.CharacteristicNumbers;
function ReynoldsNumber "Reynolds number of fluid flow"
  input Modelica.SIunits.MassFlowRate m_flow "Mass flow rate";
  input Modelica.SIunits.Length length
    "Characteristic length (hyd. diam. in pipes)";
  input Modelica.SIunits.Area A "Cross sectional area";
  input Modelica.SIunits.DynamicViscosity eta "Dynamic viscosity";
  output Modelica.SIunits.ReynoldsNumber Re "Reynolds number";

algorithm
  Re := abs(m_flow)*length/A/eta;

annotation (derivative=ReynoldsNumber_der,
    Documentation(
 info="<HTML>
                    <p>This function returns the Reynolds number of a fluid flow.<br>
                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td><td><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </td>
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
</HTML>",
    revisions="<html>
                      <ul>
                             <li> June 2007 by Kilian Link
                       </ul>
                        </html>"));
end ReynoldsNumber;
