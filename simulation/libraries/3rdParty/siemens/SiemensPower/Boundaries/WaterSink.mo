within SiemensPower.Boundaries;
model WaterSink "Pressure-enthalpy sink for simple water flows"
  import SI = SiemensPower.Units;
//  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
//    constrainedby Modelica.Media.Interfaces.PartialMedium
//                                                    annotation (choicesAllMatching=
//        true);
  parameter Boolean use_p_in = false
    "Get the pressure from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));
  parameter Boolean use_h_in= false
    "Get the temperature from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));

  parameter SI.AbsolutePressure p_start = 1.01325e5 "Pressure";
  parameter SI.SpecificEnthalpy h_start = 1e5
    "Specific enthalpy for reverse flow";

//  SI.AbsolutePressure p( start = p_start);
//  SI.SpecificEnthalpy h( start = h_start);
//  SI.SpecificEnthalpy hPortActual "Specific enthalpy";
  //SI.BaseProperties water "fluid state";//(p=port.p)
  SiemensPower.Interfaces.FluidPort_a port
    annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
           0)));                            //(redeclare package Medium = Medium)
  Modelica.Blocks.Interfaces.RealInput pIn if use_p_in
    annotation (Placement(transformation(
        origin={-40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput hIn if use_h_in
    annotation (Placement(transformation(
        origin={40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));
protected
  Modelica.Blocks.Interfaces.RealInput p_in_internal
    "Needed to connect to conditional connector";
  Modelica.Blocks.Interfaces.RealInput h_in_internal
    "Needed to connect to conditional connector";

equation
  connect(pIn, p_in_internal);
  connect(hIn, h_in_internal);

  if not use_p_in then
    p_in_internal = p_start;
  end if;
  if not use_h_in then
    h_in_internal = h_start;
  end if;

  port.p = p_in_internal;
  port.h_outflow = h_in_internal;
//  port.Xi_outflow = water.Xi;
//  hPortActual = noEvent(actualStream(port.h_outflow));

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
</HTML>",
    revisions="<html>
                      <ul>
                              <li> Feb 2009, modified for stream connectors by Haiko Steuer
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>"));
end WaterSink;
