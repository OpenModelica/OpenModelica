within SiemensPower.Utilities.PressureLoss;
partial model PartialFriction
  "Base class for friction pressure loss correlations"

 parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
    "geometry parameters of the tube "                                                     annotation(Dialog(tab="Advanced",enable=false));
 parameter Modelica.SIunits.Length dz
    "length of tube section for which friction pressure loss is wanted"                                  annotation(Dialog(tab="Advanced",enable=false));
 parameter Real lambda=0.02
    "constant friction factor (used for valve friction model only)";

  input Modelica.SIunits.Pressure p "pressure";
  input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
  input Modelica.SIunits.Density rho "mass density";
  input Modelica.SIunits.DynamicViscosity eta "dynamic viscosoty";
  input Real steamQuality "Steam quality";
  input Real xdo
    "Critical steam quality, at which the boiling crisis (e.g. dryout) occurs";
  input Modelica.SIunits.MassFlowRate m_flow "mass flow rate";

 Modelica.SIunits.Pressure dp;
 Boolean isSinglePhase;

  annotation (Documentation(info="<html>
  Any derived friction pressure loss correlation must define a relation between m_flow and dp, e.g.
dp/dz = ... * m_flow^2/(rho)
<p>
The additive friction coefficient geo.zeta_add should contribute to the pressure loss something similar to
dp/dz = zeta_add/L*rho/2*v^2
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td><td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
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
</HTML>"));
end PartialFriction;
