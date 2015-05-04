within SiemensPower.Utilities.HeatTransfer;
partial model PartialHeatTransfer
  "base class for any pipe heat transfer correlation"
  replaceable package Medium=Modelica.Media.Interfaces.PartialMedium annotation(Dialog(tab="No input", enable=false));
  parameter Integer numberOfNodes(min=1)=1 "Number of pipe segments" annotation(Dialog(tab="Advanced", enable=false));
  Modelica.SIunits.HeatFlowRate[numberOfNodes] Q_flow "Heat flow rates";
  parameter Modelica.SIunits.Area A_h "Total heat transfer area"
                                                   annotation(Dialog(tab="No input", enable=false));
  parameter Modelica.SIunits.Length d_h "Hydraulic diameter"
                                               annotation(Dialog(tab="No input", enable=false));
  parameter Modelica.SIunits.Area A_cross "Cross flow area"
                                              annotation(Dialog(tab="No input", enable=false));
  parameter Modelica.SIunits.Length L "Total pipe length"
                                            annotation(Dialog(tab="No input", enable=false));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes]
    thermalPort "Thermal port"
    annotation (Placement(transformation(extent={{-20,60},{20,80}}, rotation=0)));
  input Medium.Temperature[numberOfNodes] T;
equation

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={Ellipse(
          extent={{-60,64},{60,-56}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          fillColor={232,0,0}), Text(
          extent={{-38,26},{40,-14}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          fillColor={232,0,0},
          textString="%name")}),
                          Documentation(info="<html>
Base class for heat transfer models that can be used in distributed pipe models.
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
