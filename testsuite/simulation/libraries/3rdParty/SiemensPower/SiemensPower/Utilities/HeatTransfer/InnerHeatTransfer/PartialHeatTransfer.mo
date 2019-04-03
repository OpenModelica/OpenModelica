within SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer;
partial model PartialHeatTransfer
  "Base class for friction pressure loss correlations"

 parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe annotation(Dialog(tab="Advanced",enable=false));
 final parameter Modelica.SIunits.Length diameterInner = geoPipe.d_out-2*geoPipe.s;

 input Modelica.SIunits.Pressure p;
 input Modelica.SIunits.SpecificEnthalpy h;
 input Modelica.SIunits.Density rho;
 input Modelica.SIunits.DynamicViscosity eta;
 input Modelica.SIunits.SpecificHeatCapacity cp;
 input Modelica.SIunits.ThermalConductivity lambda;
 input Real steamQuality;
 input Modelica.SIunits.MassFlowRate m_flow;
 input Modelica.SIunits.TemperatureDifference dT;

 Modelica.SIunits.CoefficientOfHeatTransfer alpha;

annotation (Documentation(info="<html>
  Any derived inner heat transfer correlation must define the relations for the following two quantities:
  <ul>
      <li> Heat transfer coefficient  <b>alpha</b>
      <li> location of boiling crisis (dry-out) <b> xdo </b> (for single phase flow, this will bot be used, so just give a dummy value)
  </ul>
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
end PartialHeatTransfer;
