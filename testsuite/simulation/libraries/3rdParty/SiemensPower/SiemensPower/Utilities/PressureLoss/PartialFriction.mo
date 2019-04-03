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
                           <td>public </td>
                </tr>
           </table>
          <p><b><font style=\"font-size: 10pt; \">License, Copyright and Disclaimer</font></b> </p>
<p>
<blockquote><br/>Licensed by Siemens AG under the Siemens Modelica License 2</blockquote>
<blockquote><br/>Copyright  2007-2012 Siemens AG. All rights reserved.</blockquote>
<blockquote><br/>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Siemens Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"../Documents/SiemensModelicaLicense2.html\">Siemens Modelica License 2 </a>.</blockquote>
        </p>
</HTML>"));
end PartialFriction;
