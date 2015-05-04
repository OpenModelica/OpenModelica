within SiemensPower.Boundaries;
model WaterSourceMH
  "Mass flow - enthalpy boundary condition for simple fluid flow"

   import SI = SiemensPower.Units;
//  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
//    constrainedby Modelica.Media.Interfaces.PartialMedium
//                                                    annotation (choicesAllMatching=
//        true);
  parameter SI.MassFlowRate m_flow_start=1 "Mass flow rate";
  parameter SI.SpecificEnthalpy h_start=100e3 "Specific enthalpy";

  parameter Boolean use_m_flow_in = false
    "Get the mass flow rate from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));
  parameter Boolean use_h_in= false
    "Get the temperature from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));

//  SI.SpecificEnthalpy h_port_actual "Specific enthalpy";
//  Medium.BaseProperties medium "fluid state";
  SI.AbsolutePressure p;

  SiemensPower.Interfaces.FluidPort_b port( h_outflow(start=h_start), m_flow(start=m_flow_start))
    annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealInput m_flow_in if       use_m_flow_in
    annotation (Placement(transformation(
        origin={-40,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput hIn if      use_h_in
    annotation (Placement(transformation(
        origin={40,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));

protected
  Modelica.Blocks.Interfaces.RealInput m_flow_in_internal
    "Needed to connect to conditional connector";
  Modelica.Blocks.Interfaces.RealInput h_in_internal
    "Needed to connect to conditional connector";
equation

  connect(m_flow_in, m_flow_in_internal);
  connect(hIn, h_in_internal);

  if not use_m_flow_in then
    m_flow_in_internal = m_flow_start;
  end if;
  if not use_h_in then
    h_in_internal = h_start;
  end if;

  p = port.p;

  port.m_flow = -m_flow_in_internal;
  port.h_outflow  = h_in_internal;
 // port.Xi_outflow = medium.Xi;
 // h_port_actual = noEvent(actualStream(port.h_outflow));

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
end WaterSourceMH;
