within SiemensPower.Utilities.PressureLoss;
model OverallFlow
  "Both laminar and turbulent flow (Modelica.Fluid.Dissipation)"
  extends SiemensPower.Utilities.PressureLoss.PartialFriction;
  extends SiemensPower.Utilities.PressureLoss.PartialFrictionSinglePhase;

   final parameter Modelica.SIunits.Length diameterInner = geoPipe.d_out-2*geoPipe.s;
   final parameter Modelica.SIunits.Area A = Modelica.Constants.pi*0.25*diameterInner*diameterInner;

//create and parametrize input records for additional pressure loss coefficient calculation
// according to Modelica.Fluid.Dissipation rules
Modelica.Fluid.Dissipation.PressureLoss.General.dp_pressureLossCoefficient_IN_con
    DPMFLOW_ADD_IN_con(                                                                              A_cross = A);

Modelica.Fluid.Dissipation.PressureLoss.General.dp_pressureLossCoefficient_IN_var
    DPMFLOW_ADD_IN_var(                                                                              zeta_TOT=max(1e-12,geoPipe.zeta_add), rho=rho);

//create and parametrize input records for pressure loss calculation
// according to Modelica.Fluid.Dissipation rules

Modelica.Fluid.Dissipation.PressureLoss.StraightPipe.dp_overall_IN_con
    DPMFLOW_IN_con(                                                                   d_hyd=diameterInner, K=geoPipe.r, L=dz);
Modelica.Fluid.Dissipation.PressureLoss.StraightPipe.dp_overall_IN_var
    DPMFLOW_IN_var(                                                                   rho=rho, eta=eta);

equation
 //calculation of summed up pressure loss per meter
 dp/dz = Modelica.Fluid.Dissipation.PressureLoss.General.dp_pressureLossCoefficient_DP(DPMFLOW_ADD_IN_con,DPMFLOW_ADD_IN_var, m_flow)/geoPipe.L+
                 Modelica.Fluid.Dissipation.PressureLoss.StraightPipe.dp_overall_DP(DPMFLOW_IN_con,DPMFLOW_IN_var,m_flow)/dz;

  annotation (Documentation(info="<html>
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
end OverallFlow;
