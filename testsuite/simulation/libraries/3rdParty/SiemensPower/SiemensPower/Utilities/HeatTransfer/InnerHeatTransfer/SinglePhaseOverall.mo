within SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer;
model SinglePhaseOverall
  "laminar or turbulent single phase flow (Modelica.Fluid.Dissipation)"
  extends
    SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransfer;

//create and parameterize input records for heat transfer coefficient calculation
// according to Modelica.Fluid.Dissipation rules
Modelica.Fluid.Dissipation.HeatTransfer.StraightPipe.kc_overall_IN_con
KC_IN_con(d_hyd = diameterInner, L = geoPipe.L, roughness =
Modelica.Fluid.Dissipation.Utilities.Types.Roughness.Considered, target = Modelica.Fluid.Dissipation.Utilities.Types.HeatTransferBoundary.UHFuUFF);
Modelica.Fluid.Dissipation.HeatTransfer.StraightPipe.kc_overall_IN_var KC_IN_var(cp = cp, eta = eta, lambda = lambda, rho = rho, m_flow = m_flow);
equation
 alpha = Modelica.Fluid.Dissipation.HeatTransfer.StraightPipe.kc_overall_KC(KC_IN_con, KC_IN_var);

annotation (Documentation(info="<html>
  This simple inner heat transfer correlation is good for single phase flow both in laminar and turbulent region.
</html><HTML>
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
end SinglePhaseOverall;
