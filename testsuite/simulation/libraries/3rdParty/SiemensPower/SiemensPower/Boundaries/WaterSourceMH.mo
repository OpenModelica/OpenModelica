within SiemensPower.Boundaries;
model WaterSourceMH
  "Mass flow - enthalpy boundary condition for simple fluid flow"

  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    constrainedby Modelica.Media.Interfaces.PartialMedium
                                                    annotation (choicesAllMatching=
        true);
  parameter Medium.MassFlowRate m_flow_start=1 "Mass flow rate";
  parameter Medium.SpecificEnthalpy h_start=100e3 "Specific enthalpy";
  Medium.SpecificEnthalpy h_port_actual "Specific enthalpy";
  Medium.BaseProperties medium "fluid state";
  Modelica.Fluid.Interfaces.FluidPort_b port(redeclare package Medium = Medium, h_outflow(start=h_start), m_flow(start=m_flow_start))
    annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
   Modelica.Blocks.Interfaces.RealInput m_flowIn
    annotation (Placement(transformation(
        origin={-40,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput hIn
    annotation (Placement(transformation(
        origin={40,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
equation

  if cardinality(m_flowIn) == 0 then
    m_flowIn = m_flow_start;
  end if;
  if cardinality(hIn) == 0 then
    hIn = h_start;
  end if;

  medium.p = port.p;
  medium.h = hIn;
  medium.Xi = Medium.X_default[1:Medium.nXi];

  port.m_flow = -m_flowIn;
  port.h_outflow  = medium.h;
  port.Xi_outflow = medium.Xi;
  h_port_actual = noEvent(actualStream(port.h_outflow));

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-80,40},{80,-40}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-12,-20},{66,0},{-12,20},{34,0},{-12,-20}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(extent={{-100,-52},{100,-80}}, textString="%name"),
        Text(
          extent={{46,78},{96,48}},
          lineColor={0,128,255},
          textString="h"),
        Text(
          extent={{-94,74},{-44,44}},
          lineColor={0,128,255},
          textString="m"),
        Ellipse(
          extent={{-70,70},{-68,68}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid)}),       Documentation(
 info="<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>mass flow rate </li>
<li>specific enthalpy </li>
</ul></p>

</html>
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
                              <li> Feb 2009, modified for stream connectors by Haiko Steuer
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>"));
end WaterSourceMH;
