within SiemensPower.Interfaces;
model portHeat "Closing any heat port"
  import SI = Modelica.SIunits;

  parameter Integer numberOfNodes=2 "Number of nodes";
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port[numberOfNodes]
    "heat port"
    annotation (Placement(transformation(extent={{-16,20},{16,48}}, rotation=0)));

  // changed for Dymola Version 7.4 FD01
  // now get this warning:
  // This class has a top-level outer Twall, you can only use this class as a sub-component.
  // You have to add an inner element when using this.
  // outer input SI.Temperature Twall[numberOfNodes];
  outer input Real TWall[numberOfNodes];
  SI.HeatFlowRate Q_flow[numberOfNodes];

equation
 TWall=port.T;
 Q_flow = port.Q_flow;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={Ellipse(
          extent={{-20,20},{20,-40}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={191,0,0},
          fillPattern=FillPattern.Solid)}),
                                    Documentation(info="<html>
<p>This short model can be used to complete a heat-port connector vector!
It is used in any tube with wall.
</p>
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
</HTML>",
      revisions="<html>
<ul>
<li> January 2007, by Haiko Steuer
</ul>
</html>"));
end portHeat;
