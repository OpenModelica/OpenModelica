within SiemensPowerOMCtest.Boundaries;
model GasSource "Flowrate source for gas flows"
  replaceable package Medium = Modelica.Media.Air.SimpleAir constrainedby
    Modelica.Media.Interfaces.PartialMedium "Medium model"
                                                annotation (
    choicesAllMatching=true);
  Medium.BaseProperties gas(
    p(start=p_start),
    T(start=T_start),
    Xi(start=Xi_start[1:Medium.nXi]));
  parameter Medium.AbsolutePressure p_start=101325 "Nominal pressure"   annotation(Dialog(tab="Advanced"));
  parameter Medium.Temperature T_start=300 "Temperature";
  parameter Medium.MassFraction Xi_start[Medium.nX]=Medium.reference_X
    "Gas composition";
  parameter Medium.MassFlowRate m_flow_start= 0 "Mass flow rate";

  Medium.Temperature TPortActual;

  Medium.MassFlowRate m_flow;
  SiemensPowerOMCtest.Interfaces.portGasOut port(
                                         redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealInput m_flow_set
    annotation (Placement(transformation(
        origin={-60,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput T_set
    annotation (Placement(transformation(
        origin={0,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput Xi_set[Medium.nX]
    annotation (Placement(transformation(
        origin={60,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
equation

  port.m_flow = -m_flow;
  port.p = gas.p;

  m_flow = m_flow_set;
  if cardinality(m_flow_set) == 0 then
    m_flow_set = m_flow_start "Flow rate set by parameter";
  end if;

  gas.T = T_set;
  if cardinality(T_set) == 0 then
    T_set = T_start "Temperature set by parameter";
  end if;

  gas.Xi = Xi_set[1:Medium.nXi];
  if cardinality(Xi_set) == 0 then
    Xi_set = Xi_start "Composition set by parameter";
  end if;

  port.h_outflow  = gas.h;
  port.Xi_outflow = gas.Xi;
  TPortActual=noEvent(Medium.temperature_phX(port.p, actualStream(port.h_outflow), actualStream(port.Xi_outflow)));

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Text(extent={{-112,72},{-62,42}}, textString="m"),
        Text(extent={{-114,98},{-64,58}}, textString="."),
        Text(extent={{-48,72},{2,42}}, textString="T"),
        Text(extent={{64,72},{114,42}}, textString="X"),
        Rectangle(
          extent={{-80,40},{80,-40}},
          lineColor={128,128,128},
          fillColor={159,159,223},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-12,-20},{66,0},{-12,20},{34,0},{-12,-20}},
          lineColor={128,128,128},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-100,-52},{100,-80}}, textString="%name")}),
                                                   Documentation(info="<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>mass flow rate </li>
<li>temperature </li>
<li>composition </li>
</ul></p>
<p><h4>Modelling options</h4></p>
<p>The actual gas used in the component is determined by the replaceable <code>Medium</code> package. In the case of multiple component, variable composition gases, the nominal gas composition is given by <code>X0</code>,whose default value is <code>Medium.reference_X</code> . </p>
<p>If the <code>mdot_in</code> connector is wired, then the source massflowrate is given by the corresponding signal, otherwise it is fixed to <code>m_flow0</code>.</p>
<p>If the <code>T_in</code> connector is wired, then the source temperature is given by the corresponding signal, otherwise it is fixed to <code>T0</code>.</p>
<p>If the <code>X_in</code> connector is wired, then the source massfraction is given by the corresponding signal, otherwise it is fixed to <code>X0</code>.</p>

</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:\">Kilian Link</a> </td>
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
<li> Feb 2009, modified for stream connectors by Haiko Steuer
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>August 26, 2005</i>
    by <a href=\"mailto:jonas.eborn@modelon.se\">Jonas Eborn</a>:<br>
       First release.</li>
</ul>
</html>"),
    DymolaStoredErrors);
end GasSource;
