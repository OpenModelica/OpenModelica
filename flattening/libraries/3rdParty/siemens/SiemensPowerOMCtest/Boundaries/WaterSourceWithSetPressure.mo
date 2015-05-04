within SiemensPowerOMCtest.Boundaries;
model WaterSourceWithSetPressure
  "Pressure-enthalpy source for simple water flows"
 replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
     constrainedby Modelica.Media.Interfaces.PartialMedium
        annotation (choicesAllMatching=true);
  parameter Medium.AbsolutePressure p0=1.01325e5 "Pressure";
  parameter Medium.SpecificEnthalpy h0=1e5 "Specific enthalpy";
  Medium.SpecificEnthalpy hPortActual "Specific enthalpy";
  Medium.BaseProperties medium "fluid state";
  Modelica.Fluid.Interfaces.FluidPort_b port(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealInput pIn
    annotation (Placement(transformation(
        origin={-40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput hIn
    annotation (Placement(transformation(
        origin={40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));

equation
  if cardinality(pIn) == 0 then
    pIn = p0;
  end if;
  if cardinality(hIn) == 0 then
    hIn = h0;
  end if;

  medium.p = pIn;
  medium.h = hIn;
  medium.Xi = Medium.X_default[1:Medium.nXi];

  port.p = medium.p;
  port.h_outflow = medium.h;
  port.Xi_outflow = medium.Xi;
  hPortActual = noEvent(actualStream(port.h_outflow));

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Text(extent={{-100,92},{-50,62}}, textString="p"),
        Text(extent={{50,92},{100,62}}, textString="h"),
        Ellipse(
          extent={{-80,80},{80,-80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-20,34},{28,-26}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          textString="P"),
        Text(extent={{-100,-78},{100,-106}}, textString="%name")}),
                                                 Documentation(
 info="<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>pressure </li>
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
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>"));
end WaterSourceWithSetPressure;
