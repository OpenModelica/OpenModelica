within SiemensPowerOMCtest.Utilities.Functions.CharacteristicNumbers;
function ReynoldsNumber_der "time derivative of ReynoldsNumber"

  input Modelica.SIunits.MassFlowRate m_flow "Mass flow rate";
  input Modelica.SIunits.Length length
    "Characteristic length (hyd. diam. in pipes)";
  input Modelica.SIunits.Area A "Cross sectional area";
  input Modelica.SIunits.DynamicViscosity eta "Dynamic viscosity";
  input Real m_flow_der "time derivative of mass flow rate";
  input Real length_der;
  input Real A_der;
  input Real eta_der "time derivative of dynamic viscosity";
  output Real Re_der "time derivative of Reynolds number";

algorithm
  if (m_flow>0) then
    Re_der := m_flow_der*length/A/eta - eta_der*abs(m_flow)*length/(A*eta^2);
  else
    Re_der := -m_flow_der*length/A/eta - eta_der*abs(m_flow)*length/(A*eta^2);
  end if;

annotation (Documentation(
 info="<HTML>
                    <p>This function returns the time derivative of the Reynolds number of a fluid flow.<br>
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
end ReynoldsNumber_der;
