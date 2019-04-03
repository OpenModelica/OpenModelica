within SiemensPower.Boundaries;
model WaterSink "Pressure-enthalpy sink for simple water flows"

  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    constrainedby Modelica.Media.Interfaces.PartialMedium
                                                    annotation (choicesAllMatching=
        true);
  parameter Medium.AbsolutePressure p_start = 1.01325e5 "Pressure";
  parameter Medium.SpecificEnthalpy h_start = 1e5
    "Specific enthalpy for reverse flow";
  Medium.SpecificEnthalpy hPortActual "Specific enthalpy";
  Medium.BaseProperties water "fluid state";//(p=port.p)
  Modelica.Fluid.Interfaces.FluidPort_a port(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
           0)));
  Modelica.Blocks.Interfaces.RealInput p_set
    annotation (Placement(transformation(
        origin={-40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput h_set
    annotation (Placement(transformation(
        origin={40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));
equation

  if cardinality(p_set) == 0 then
    p_set = p_start;
  end if;
  if cardinality(h_set) == 0 then
    h_set = h_start;
  end if;

  water.p = p_set;
  water.h = h_set;
  water.Xi = Medium.X_default[1:Medium.nXi];

  port.p = water.p;
  port.h_outflow = water.h;
  port.Xi_outflow = water.Xi;
  hPortActual = noEvent(actualStream(port.h_outflow));

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Ellipse(
          extent={{-80,80},{80,-80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-20,34},{28,-26}},
          lineColor={255,255,255},
          textString="P"),
        Text(extent={{-100,-78},{100,-106}}, textString="%name"),
        Text(
          extent={{-96,94},{-46,64}},
          textString="p",
          lineColor={0,128,255}),
        Text(
          extent={{50,92},{100,62}},
          textString="h",
          lineColor={0,128,255})}),              Documentation(
 info="<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>pressure </li>
<li>specific enthalpy </li>
</ul></p>
<p>Note that the specific enthalpy value takes only effect in case of reverse flow. </p>

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
end WaterSink;
