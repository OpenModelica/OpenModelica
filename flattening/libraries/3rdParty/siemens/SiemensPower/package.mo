within ;
package SiemensPower "SiemensPower"


    annotation (
  version="2.1beta",
 preferedView="info",
 uses(Modelica(version="3.2")),
 conversion(from(version="1.8", script="Scripts/ConvertSiemensPower_from_1.8_to_2.0.mos"), from(version="2.0", script="Scripts/ConvertSiemensPower_from_2.0_to_2.1.mos")),
     Documentation(info="<html>
<blockquote>The SiemensPower <a href=\"http://www.modelica.org/\">Modelica</a> library contains models for power plant simulation.</blockquote><blockquote>Change requests can be submitted at the <a href=\"http://diagnostics-cvs/trac/Modelica\">SiemensPower trac</a> site. </blockquote>
<p><b><font style=\"font-size: 10pt; \">Articles</font></b></p>
<p><ul>
<li>For the user: Frequently asked questions regarding Dymola, Modelica and SiemensPower: <a href=\"http://diagnostics-cvs/trac/Modelica/wiki/Dymola/DymolaFAQ\">FAQ</a> </li>
<li>For the model developer: <a href=\"http://diagnostics-cvs/trac/Modelica/wiki/SiemensPower/ModelingGuidelines\">Guidelines</a> </li>
</ul></p>
<p><b><font style=\"font-size: 10pt; \">Contact</font></b> </p>
<blockquote><a href=\"mailto:Kilian.Link@siemens.com\">Kilian Link</a></blockquote><blockquote>Siemens AG</blockquote><blockquote>Energy Sector </blockquote><blockquote>E F ES EN 12 </blockquote><blockquote>P.O. Box 3220 </blockquote><blockquote>91050 Erlangen </blockquote><blockquote>Germany </blockquote>
<p><b><font style=\"font-size: 10pt; \">Copyright and Disclaimer</font></b> </p>
<blockquote><br/>Copyright  2007-2010 Siemens AG, E F ES EN 12. All rights reserved.</blockquote><blockquote><br/>The library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a>. </blockquote>
</html>",
revisions="<html>
<p>See <a href=\"http://diagnostics-cvs/trac/Modelica/roadmap\">roadmap</a> for future developments. </p>
<p><ul>
<li>August 2011, SiemensPower 2.0 based on Modelica 3.2  </li>
<li>May 2011, SiemensPower 1.8 based on Modelica 3.2  </li>
<li>Dec 2010, SiemensPower 1.7 based on Modelica 3.1 (including Modelica.Fluid) </li>
<li>June 2010, SiemensPower 1.6 based on Modelica 3.1 (including Modelica.Fluid) </li>
<li>April 2009, SiemensPower 1.4 based on Modelica.Fluid 1.0 (stream connector) </li>
<li>Feb 2009, SiemensPower 1.1 based on MSL 3.0 </li>
<li>Oct 2008, SiemensPower 1.0 based on Modelica.Fluid 1.0 Beta 2 </li>
</ul></p>
</html>"),
  DymolaStoredErrors(thetext="package SiemensPower \"SiemensPower\"

  package Blocks \"Blocks that are not contained in Control\"
    model Smoothing \"u is y with smooth derivative\"

      Modelica.Blocks.Interfaces.RealInput u annotation (Placement(transformation(
              extent={{-100,-10},{-80,10}}, rotation=0)));
      Modelica.Blocks.Interfaces.RealOutput y annotation (Placement(transformation(
              extent={{40,-10},{60,10}}, rotation=0)));
      parameter Modelica.SIunits.Time timeDelay=0.01;

    initial equation
      u=y;

    equation
      der(y)=(u-y)/timeDelay;

      annotation (Diagram(graphics),
                           Icon(coordinateSystem(preserveAspectRatio=false, extent=
                {{-100,-100},{100,100}}), graphics={Rectangle(
              extent={{-80,20},{40,-20}},
              lineColor={0,0,0},
              pattern=LinePattern.None,
              fillPattern=FillPattern.VerticalCylinder,
              fillColor={0,61,121}), Text(
              extent={{-78,18},{40,-18}},
              lineColor={0,0,0},
              pattern=LinePattern.None,
              fillPattern=FillPattern.VerticalCylinder,
              fillColor={170,213,255},
              textString=
                   \"%name\")}),
    Documentation(info=\"<html>
<p>This block guarantees an output signal with smooth time derivative.</p>
<p>It represents a simple time delay (PT1) with time constant T </p>

</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                 <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</html>\"));
    end Smoothing;

    model TimeTable
      \"Time table with signal, which has a continous derivative (if desired)\"
    extends Modelica.Blocks.Interfaces.SO;
        parameter Real table[:, 2]=[0, 0; 1, 1; 2, 4]
        \"Table matrix (time = first column)\";
      parameter Modelica.SIunits.Time timeDelay=0.01 \"Delay time\";
      Modelica.Blocks.Sources.TimeTable originalTable(table=table)
        annotation (Placement(transformation(extent={{-32,-10},{-12,10}}, rotation=
                0)));
      SiemensPower.Blocks.Smoothing C1signal(timeDelay=timeDelay)
                           annotation (Placement(transformation(extent={{22,-10},{
                42,10}}, rotation=0)));
      Modelica.Blocks.Interfaces.RealOutput yOriginal
        \"original time table function\"
        annotation (Placement(transformation(extent={{100,-92},{120,-72}}, rotation=
               0)));
    equation
       connect(originalTable.y, C1signal.u)
        annotation (Line(points={{-11,0},{23,0}}, color={0,0,127}));
      connect(C1signal.y, y)
        annotation (Line(points={{37,0},{110,0}}, color={0,0,127}));
      connect(originalTable.y, yOriginal) annotation (Line(points={{-11,0},{4,0},{4,
              -82},{110,-82}}, color={0,0,127}));

    annotation (Diagram(graphics),
                         Icon(graphics={
            Line(points={{-70,-50},{-70,70},{30,70},{30,-50},{-70,-50},{-70,-20},{
                  30,-20},{30,10},{-70,10},{-70,40},{30,40},{30,70},{-20,70},{-20,-51}},
                color={0,0,0}),
            Line(points={{-81,82},{-81,-66}}, color={192,192,192}),
            Line(points={{-83,-62},{39,-62}}, color={192,192,192}),
            Polygon(
              points={{58,-62},{36,-54},{36,-70},{58,-62}},
              lineColor={192,192,192},
              fillColor={192,192,192},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{-80,96},{-88,74},{-72,74},{-80,96}},
              lineColor={192,192,192},
              fillColor={192,192,192},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{30,18},{98,-14}},
              lineColor={0,0,255},
              textString=\"delayed\"),
            Text(
              extent={{20,-66},{88,-98}},
              lineColor={0,0,255},
              textString=\"original\")}),
    Documentation(info=\"<html>
<p>This is a block giving signals with continous derivative from a time table.</p><p>The original time table function is delayed in time with time constant Tdel, which should be small compared to typical time scales of the table.</p><p>The second output gives the original time table signal in case you dont want any delay. </p>

</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</html>\"));
    end TimeTable;
  annotation (Documentation(info=\"<html>
This package contains blocks if not specified in the Control package.
</html>\"));
  end Blocks;

  package Boundaries \"Sources and sinks\"
    model GasSinkP \"Pressure sink for gas flows\"
      replaceable package Medium = Modelica.Media.Air.SimpleAir constrainedby
        Modelica.Media.Interfaces.PartialMedium \"Medium model\"
                                                      annotation (
          choicesAllMatching=true);
      parameter .Pressure p_start=101325 \"Pressure\";
      parameter Medium.Temperature T_start=300 \"Temperature for reverse flow\";
      parameter Medium.MassFraction Xi_start[Medium.nX]=Medium.reference_X
        \"Gas composition for reverse flow\";
      SiemensPower.Interfaces.portGasIn portGas(redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
               0)));
      Modelica.Blocks.Interfaces.RealInput p_In
        annotation (Placement(transformation(
            origin={-60,60},
            extent={{-20,-20},{20,20}},
            rotation=270)));
      Modelica.Blocks.Interfaces.RealInput T_In
        annotation (Placement(transformation(
            origin={0,90},
            extent={{-20,-20},{20,20}},
            rotation=270)));
      Modelica.Blocks.Interfaces.RealInput Xi_In[Medium.nX]
        annotation (Placement(transformation(
            origin={60,60},
            extent={{-20,-20},{20,20}},
            rotation=270)));

      Medium.BaseProperties gas(
        p(start=p_start),
        T(start=T_start),
        Xi(start=Xi_start[1:Medium.nXi]));

      Medium.Temperature TPortActual;

    equation
     portGas.p = gas.p;
     gas.p = p_In;

      if cardinality(p_In) == 0 then
        p_In = p_start \"Pressure set by parameter\";
      end if;

      gas.T = T_In;
      if cardinality(T_In) == 0 then
        T_In = T_start \"Temperature set by parameter\";
      end if;

      gas.Xi = Xi_In[1:Medium.nXi];
      if cardinality(Xi_In) == 0 then
        Xi_In = Xi_start \"Composition set by parameter\";
      end if;

      portGas.h_outflow  = gas.h;
      portGas.Xi_outflow = gas.Xi;
      TPortActual=noEvent(Medium.temperature_phX(portGas.p, actualStream(portGas.h_outflow), actualStream(portGas.Xi_outflow)));

      annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
                -100},{100,100}}), graphics={
            Text(extent={{-114,72},{-64,42}}, textString=\"p\"),
            Text(extent={{-48,102},{2,72}}, textString=\"T\"),
            Text(extent={{64,72},{114,42}}, textString=\"X\"),
            Ellipse(
              extent={{-80,74},{80,-86}},
              lineColor={128,128,128},
              fillColor={159,159,223},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-20,28},{28,-32}},
              lineColor={255,255,255},
              textString=\"P\"),
            Text(
              extent={{-88,-82},{90,-132}},
              lineColor={0,0,0},
              textString=\"%name\")}),                   Documentation(info=\"<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>pressure </li>
<li>temperature </li>
<li>composition </li>
</ul></p>
<p><h4>Modelling options</h4></p>
<p>The actual gas used in the component is determined by the replaceable <code>Medium</code> package. In the case o"
         + "f multiple component, variable composition gases, the nominal gas composition is given by <code>Xi_start</code>, whose default value is <code>Medium.reference_X</code> . </p>
<p>If <code>R</code> is set to zero, the pressure sink is ideal; otherwise, the inlet pressure increases proportionally to the outgoing flowrate.</p>
<p>If the <code>p_In</code> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <code>p_start</code>.</p>
<p>If the <code>T_In</code> connector is wired, then the source temperature is given by the corresponding signal, otherwise it is fixed to <code>T_start</code>.</p>
<p>If the <code>Xi_In</code> connector is wired, then the source massfraction is given by the corresponding signal, otherwise it is fixed to <code>Xi_start</code>.</p>

</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                 <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>August 26, 2005</i>
    by <a href=\\\"mailto:jonas.eborn@modelon.se\\\">Jonas Eborn</a>:<br>
       First release.</li>
</ul>
</html>\"));
    end GasSinkP;

    model GasSource \"Flowrate source for gas flows\"
      replaceable package Medium = Modelica.Media.Air.SimpleAir constrainedby
        Modelica.Media.Interfaces.PartialMedium \"Medium model\"
                                                    annotation (
        choicesAllMatching=true);
      Medium.BaseProperties gas(
        p(start=p_start),
        T(start=T_start),
        Xi(start=Xi_start[1:Medium.nXi]));
      parameter Medium.AbsolutePressure p_start=101325 \"Nominal pressure\"   annotation(Dialog(tab=\"Advanced\"));
      parameter Medium.Temperature T_start=300 \"Temperature\";
      parameter Medium.MassFraction Xi_start[Medium.nX]=Medium.reference_X
        \"Gas composition\";
      parameter Medium.MassFlowRate m_flow_start= 0 \"Mass flow rate\";

      Medium.Temperature TPortActual;

      Medium.MassFlowRate m_flow;
      SiemensPower.Interfaces.portGasOut port(
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
        m_flow_set = m_flow_start \"Flow rate set by parameter\";
      end if;

      gas.T = T_set;
      if cardinality(T_set) == 0 then
        T_set = T_start \"Temperature set by parameter\";
      end if;

      gas.Xi = Xi_set[1:Medium.nXi];
      if cardinality(Xi_set) == 0 then
        Xi_set = Xi_start \"Composition set by parameter\";
      end if;

      port.h_outflow  = gas.h;
      port.Xi_outflow = gas.Xi;
      TPortActual=noEvent(Medium.temperature_phX(port.p, actualStream(port.h_outflow), actualStream(port.Xi_outflow)));

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Text(extent={{-112,72},{-62,42}}, textString=\"m\"),
            Text(extent={{-114,98},{-64,58}}, textString=\".\"),
            Text(extent={{-48,72},{2,42}}, textString=\"T\"),
            Text(extent={{64,72},{114,42}}, textString=\"X\"),
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
            Text(extent={{-100,-52},{100,-80}}, textString=\"%name\")}),
                                                       Documentation(info=\"<html>
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
                              <td><a href=\\\"mailto:\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> Feb 2009, modified for stream connectors by Haiko Steuer
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>August 26, 2005</i>
    by <a href=\\\"mailto:jonas.eborn@modelon.se\\\">Jonas Eborn</a>:<br>
       First release.</li>
</ul>
</html>\"),
        DymolaStoredErrors);
    end GasSource;

    model PrescribedHeatFlow
      \"Prescribed heat flow boundary condition for discretized aggregate\"
      parameter Integer numberOfCells=2 \"Number of cells\";

      Modelica.Blocks.Interfaces.RealInput Q_flow \"Overall heat input\"
            annotation (Placement(transformation(
            origin={-100,0},
            extent={{20,-20},{-20,20}},
            rotation=180)));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfCells] portsOut
        \"Heat output distribution\"
                                 annotation (Placement(transformation(extent={{90,
                -10},{110,10}}, rotation=0)));
    equation
      portsOut.Q_flow = -Q_flow*ones(numberOfCells)/numberOfCells;

     annotation (
        Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
                100}}), graphics={
            Line(
              points={{-60,-20},{40,-20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-60,20},{40,20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-80,0},{-60,-20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-80,0},{-60,20}},
              color={191,0,0},
              thickness=0.5),
            Polygon(
              points={{40,0},{40,40},{70,20},{40,0}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{40,-40},{40,0},{70,-20},{40,-40}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid),
            Rectangle(
              extent={{70,40},{90,-40}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid),
            Text(extent={{-134,120},{132,60}}, textString=\"%name\")}),
        Documentation(info=\"<HTML>
<p>
This model allows a specified amount of heat flow rate to be \\\"injected\\\"
into a thermal system.<br>
The amount of hea" + "t at each cell is given by Q_flow/N. <br>
The heat flows <b>into</b> the component to which the component PrescribedHeatFlow is connected,
if the input signal is positive.
</p>
</HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                  <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",
    revisions=\"<html>
<ul>
<li> December 2006, added  by Haiko Steuer
</ul>
</html>\"),     Diagram(graphics={
            Line(
              points={{-60,-20},{68,-20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-60,20},{68,20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-80,0},{-60,-20}},
              color={191,0,0},
              thickness=0.5),
            Line(
              points={{-80,0},{-60,20}},
              color={191,0,0},
              thickness=0.5),
            Polygon(
              points={{60,0},{60,40},{90,20},{60,0}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{60,-40},{60,0},{90,-20},{60,-40}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid)}));
    end PrescribedHeatFlow;

    model Reservoir \"Thermal reservoir for discretized aggregate\"
      parameter Integer N=2 \"Number of cells\";
      parameter String reservoir=\"heat\" \"Kind of reservoir\"
             annotation(choices(choice=\"heat\" \"Heat reservoir\",
                             choice=\"temperature\" \"Temperature reservoir\"));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b ports[N]
        \"Heat output distribution\"
        annotation (Placement(transformation(extent={{-20,-92},{20,-50}}, rotation=
                0)));
      parameter Real T_set=500 \"Fixed temperature\"
          annotation (Dialog(enable=reservoir==\"temperature\"));
       parameter SiemensPower.Units.HeatFlowRate Q_flow_set=0
        \"Fixed heat flow rate(overall)\"
          annotation (Dialog(enable=reservoir==\"heat\"));
      SiemensPower.Units.Temperature T[N](each start=T_set);
      SiemensPower.Units.HeatFlowRate Q_flow[N](each start=Q_flow_set);

    equation
    if (reservoir==\"temperature\") then
            T = ones(N)*T_set;
    else
            Q_flow=ones(N)*Q_flow_set/N;
    end if;

     ports.T = T;
     ports.Q_flow + Q_flow = zeros(N);

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Rectangle(
              extent={{-100,22},{98,-50}},
              lineColor={255,255,255},
              fillColor={195,0,0},
              fillPattern=FillPattern.Solid), Text(
              extent={{-96,18},{96,-42}},
              lineColor={255,255,255},
              fillColor={190,0,0},
              fillPattern=FillPattern.Backward,
              textString=\"%reservoir\")}),
    Documentation(info=\"<html>
<p>
This model allows a specified amount of heat flow rate to be \\\"injected\\\"
into a thermal system or specify a certain <b>temperature reservoir</b>.<br>
In case of a <b>heat reservoir</b>, the amount of heat at each cell is given by Q0/N. <br>
The heat flows <b>into</b> the component to which the component PrescribedHeatFlow is connected,
if the input signal is positive.
</p>
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                 <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</html>\"),
        Diagram(graphics));
    end Reservoir;

    model WaterSink \"Pressure-enthalpy sink for simple water flows\"
      import SI = SiemensPower.Units;
    //  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    //    constrainedby Modelica.Media.Interfaces.PartialMedium
    //                                                    annotation (choicesAllMatching=
    //        true);
      parameter SI.AbsolutePressure p_start = 1.01325e5 \"Pressure\";
      parameter SI.SpecificEnthalpy h_start = 1e5
        \"Specific enthalpy for reverse flow\";
      SI.AbsolutePressure p( start = p_start);
      SI.SpecificEnthalpy h( start = h_start);
      SI.SpecificEnthalpy hPortActual \"Specific enthalpy\";
      //SI.BaseProperties water \"fluid state\";//(p=port.p)
      SiemensPower.Interfaces.FluidPort_a port
        annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
               0)));                            //(redeclare package Medium = Medium)
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

      p = p_set;
      h = h_set;
    //  water.Xi = Medium.X_default[1:Medium.nXi];

      port.p = p;
      port.h_outflow = h;
    //  port.Xi_outflow = water.Xi;
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
              textString=\"P\"),
            Text(extent={{-100,-78},{100,-106}}, textString=\"%name\"),
            Text(
              extent={{-96,94},{-46,64}},
              textString=\"p\",
              lineColor={0,128,255}),
            Text(
              extent={{50,92},{100,62}},
              textString=\"h\",
              lineColor={0,128,255})}),              Documentation(
     info=\"<html>
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
                                 <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",
        revisions=\"<html>
                      <ul>
                              <li> Feb 2009, modified for stream connectors by Haiko Steuer
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>\"));
    end WaterSink;

    model WaterSourceMH
      \"Mass flow - enthalpy boundary condition for simple flu" + "id flow\"

       import SI = SiemensPower.Units;
    //  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    //    constrainedby Modelica.Media.Interfaces.PartialMedium
    //                                                    annotation (choicesAllMatching=
    //        true);
      parameter SI.MassFlowRate m_flow_start=1 \"Mass flow rate\";
      parameter SI.SpecificEnthalpy h_start=100e3 \"Specific enthalpy\";
      SI.SpecificEnthalpy h_port_actual \"Specific enthalpy\";
    //  Medium.BaseProperties medium \"fluid state\";
      SI.AbsolutePressure p;
      SI.SpecificEnthalpy h( start = h_start);
      SiemensPower.Interfaces.FluidPort_b port( h_outflow(start=h_start), m_flow(start=m_flow_start))
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

      p = port.p;
      h = hIn;
      //medium.Xi = Medium.X_default[1:Medium.nXi];

      port.m_flow = -m_flowIn;
      port.h_outflow  = h;
     // port.Xi_outflow = medium.Xi;
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
            Text(extent={{-100,-52},{100,-80}}, textString=\"%name\"),
            Text(
              extent={{46,78},{96,48}},
              lineColor={0,128,255},
              textString=\"h\"),
            Text(
              extent={{-94,74},{-44,44}},
              lineColor={0,128,255},
              textString=\"m\"),
            Ellipse(
              extent={{-70,70},{-68,68}},
              lineColor={0,0,255},
              pattern=LinePattern.None,
              fillColor={0,128,255},
              fillPattern=FillPattern.Solid)}),       Documentation(
     info=\"<html>
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
                              <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",
        revisions=\"<html>
                      <ul>
                              <li> Feb 2009, modified for stream connectors by Haiko Steuer
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>\"));
    end WaterSourceMH;

    model WaterSourceWithSetPressure
      \"Pressure-enthalpy source for simple water flows\"
         import SI = SiemensPower.Units;
     //replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
     //    constrainedby Modelica.Media.Interfaces.PartialMedium
    //        annotation (choicesAllMatching=true);
      parameter SI.AbsolutePressure p0=1.01325e5 \"Pressure\";
      parameter SI.SpecificEnthalpy h0=1e5 \"Specific enthalpy\";
      SI.AbsolutePressure p;
      SI.SpecificEnthalpy h;
      SI.SpecificEnthalpy hPortActual \"Specific enthalpy\";
      //Medium.BaseProperties medium \"fluid state\";
      SiemensPower.Interfaces.FluidPort_b port
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

      p = pIn;
      h = hIn;
     // medium.Xi = Medium.X_default[1:Medium.nXi];

      port.p = p;
      port.h_outflow = h;
      //port.Xi_outflow = medium.Xi;
      hPortActual = noEvent(actualStream(port.h_outflow));

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Text(extent={{-100,92},{-50,62}}, textString=\"p\"),
            Text(extent={{50,92},{100,62}}, textString=\"h\"),
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
              textString=\"P\"),
            Text(extent={{-100,-78},{100,-106}}, textString=\"%name\")}),
                                                     Documentation(
     info=\"<html>
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
                           <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",
        revisions=\"<html>
                      <ul>
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>\"));
    end WaterSourceWithSetPressure;
  annotation (Documentation(info=\"<html>
This package contains sources and sinks fluids and heat.
</html>\"));
  end Boundaries;

  package Components \"Aggregates\"
    package FlueGasZones \"Gas side topology and heat transfer\"
      model FlueGasZoneSingleTubeOwnMedia
        \"Flue gas zone including a single water/steam tube as basis component for higher level flue gas zones\"

        import SI = SiemensPower.Units;
        constant Real pi=Modelica.Constants.pi;

       replaceable package GasMedium =  SiemensPower.Media.ExhaustGas constrainedby
          Modelica.Media.Interfaces.PartialMedium \"Flue gas medium\"
            annotation (   choicesAllMatching=true, Dialog(group=\"Media\"));

        replaceable package H2OMedium = Modelica.Media.Water.WaterIF97_ph
          constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium
          \"Water/steam medium\"                            annotation (choicesAllMatching=
              true, Dialog(group=\"Media\"));

      //  parameter Integer Np=10 \"Number of parallel layers (= no of gas nodes)\";
        parameter Integer numberOfTubeNodes=2 \"Number of water nodes per tube\";
        parameter Integer numberOfWallLayers(min=1)=3 \"Number of wall layers\" annotation(choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
        parameter Modelica.Fluid.Types.HydraulicResistance
          hydraulicResistance_gas =                                                2
          \"Hydraulic conductance (for gas pressure drop)\";
        parameter SI.CoefficientOfHeatTransfer alphaOffset=0.5e3
          \"alpha offset (in case of verysimple=true)\"                    annotation(Dialog(tab=\"Inner heat transfer\", enable=verysimple));
        parameter Real alphaFactor=1.0
          \"Factor for state dependent alpha term (in case " + "of verysimple=true)\"                    annotation(Dialog(tab=\"Inner heat transfer\", enable=verysimple));

        parameter SiemensPower.Units.MassFlowRate m_flow_start=19.05
          \"Total water/steam mass flow rate\" annotation (Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter H2OMedium.AbsolutePressure pIn_start=pOut_start+2e5
          \"start value for inlet pressure\"                            annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter H2OMedium.AbsolutePressure pOut_start=137e5
          \"start value for outlet pressure\"                              annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter H2OMedium.SpecificEnthalpy hIn_start=500e3
          \"start value for inlet enthalpy\"                                      annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter H2OMedium.SpecificEnthalpy hOut_start=hIn_start
          \"start value for outlet enthalpy\"                                   annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter SI.Pressure pGas_start=1.0e5 \"Gas pressure\"
          annotation (Dialog(tab=\"Initialization\", group=\"Gas\"));
        parameter H2OMedium.Temperature TGasIn_start=300.0
          \"Inlet gas temperature\"
          annotation (Dialog(tab=\"Initialization\", group=\"Gas\"));
        parameter H2OMedium.Temperature TGasOut_start=TGasIn_start
          \"Outlet gas temperature\"
          annotation (Dialog(tab=\"Initialization\", group=\"Gas\"));
        parameter GasMedium.MassFlowRate m_flowGas_start=1 \"Gas mass flow rate\"
                               annotation (Dialog(tab=\"Initialization\", group=\"Gas\"));
        parameter SiemensPower.Utilities.Structures.FgzGeo geoFGZ
          \"Geometry of flue gas zone\"  annotation (Dialog(group=\"Geometry\"));
        parameter SiemensPower.Utilities.Structures.Fins geoFins
          \"Geometry of outer wall fins\"   annotation (Dialog(group=\"Geometry\"));
        parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
          \"Geometry of tubes\"                                                             annotation (Dialog(group=\"Geometry\"));
        parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
          \"Tube wall properties\"                                                           annotation (Dialog(group=\"Media\"));
        parameter Real cleanliness=1.0 \"Cleanliness factor\";
        parameter Real heatloss=0.5 \"Heat loss to ambient in %\";
        parameter Boolean hasCriticalData=(if GasMedium.nX>1 then true else false) annotation(Dialog(tab=\"No input\", enable=false));
        parameter SI.Length d_ch_Re = (if geoFins.finned then geoPipe.d_out else 0.5*pi*geoPipe.d_out) annotation(Dialog(tab=\"No input\", enable=false));
        parameter SI.Area Ah=geoPipe.Nt*pi*geoPipe.d_out*geoPipe.L
          \"Heat transfer area of unfinned tubes\" annotation(Dialog(tab=\"No input\", enable=false));

        SiemensPower.Interfaces.portGasIn portGasIn(redeclare package Medium = GasMedium, m_flow(start=m_flowGas_start))
          annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
                 0)));
        SiemensPower.Interfaces.portGasOut portGasOut(
                                                     redeclare package Medium
            =                                                                   GasMedium, m_flow(start=-m_flowGas_start)) annotation (Placement(
              transformation(extent={{80,-20},{120,20}}, rotation=0)));
         Modelica.Fluid.Interfaces.FluidPort_a portIn(redeclare package Medium
            =                                                                    H2OMedium, m_flow(start=m_flow_start))
          \"water inlet\"
          annotation (Placement(transformation(extent={{-20,-100},{20,-60}}, rotation=
                 0)));
        Modelica.Fluid.Interfaces.FluidPort_b portOut(redeclare package Medium
            =                                                                    H2OMedium, m_flow(start=-m_flow_start))
          \"water moutlet\"
          annotation (Placement(transformation(extent={{-20,60},{20,100}}, rotation=0)));
        SiemensPower.Components.Pipes.TubeOwnMedia tube(
          redeclare package Medium = H2OMedium,
          numberOfNodes=numberOfTubeNodes,
          geoPipe=geoPipe,
          considerMassAccelaration=false,
          considerDynamicPressure=false,
          pIn_start=pIn_start,
          pOut_start=pOut_start,
          hIn_start=hIn_start,
          hOut_start=hOut_start,
          m_flow_start=m_flow_start,
          metal=metal,
          numberOfWallLayers=numberOfWallLayers,
          useINTH2O=false)             annotation (Placement(transformation(
              origin={-2,4},
              extent={{-10,-10},{10,10}},
              rotation=90)));

      replaceable Utilities.HeatTransfer.HeatTransfer_constAlpha heatTransfer(
          redeclare package Medium = GasMedium,
          numberOfNodes=numberOfTubeNodes,
          lengthRe=d_ch_Re,
          lengthNu = 0.5*pi*geoPipe.d_out,
          AHeatTransfer=Ah,
          ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
          geoFGZ=geoFGZ,
          geoFins=geoFins,
          geoPipe=geoPipe,
          m_flow=m_flow,
          state=state) constrainedby
          SiemensPower.Utilities.HeatTransfer.HeatTransferBaseClass(
          redeclare package Medium = GasMedium,
          numberOfNodes=numberOfTubeNodes,
          lengthRe=d_ch_Re,
          lengthNu = 0.5*pi*geoPipe.d_out,
          AHeatTransfer=Ah,
          ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
          geoFGZ=geoFGZ,
          geoFins=geoFins,
          geoPipe=geoPipe,
          m_flow=m_flow,
          state=state) \"Convective heat transfer\"
                  annotation (Dialog(tab=\"General\", group=\"Outer heat transfer\"),editButton=true,choicesAllMatching,
          Placement(transformation(extent={{-72,-46},{-32,-6}}, rotation=0)));

        GasMedium.BaseProperties mediumOut(
          p(start=pGas_start),
          T(start=TGasOut_start));
        GasMedium.BaseProperties medium(
          p(start=pGas_start),
          T(start=0.5*(TGasOut_start+TGasIn_start)));
         GasMedium.BaseProperties mediumIn(
          p(start=pGas_start),
          T(start=TGasIn_start));
        GasMedium.MassFlowRate m_flowGas(start=m_flowGas_start)
          \"Mass flow rate\";
        GasMedium.ThermodynamicState state(T(start=0.5*(TGasIn_start+TGasOut_start)),  p(start=pGas_start))
          \"gas medium properties\";
        GasMedium.MassFlowRate m_flow(start=m_flowGas_start) \"Mass flow rate\";
       inner GasMedium.Temperature TWall[numberOfTubeNodes];

        SI.Volume VGas \"volume of gas layer\";
      //  SI.Temperature TwallOutAv;
        SI.TemperatureDifference dT[numberOfTubeNodes];
       SiemensPower.Interfaces.portHeat heatPortToWall(numberOfNodes=numberOfTubeNodes);

      SI.HeatFlowRate[numberOfTubeNodes] Q_flowToAmbient
          \"Heat flow rates to ambient\";
      initial equation
        der(mediumOut.h)=0;

      equation

        state=medium.state;
        m_flow = m_flowGas;

        medium.p  = (portGasIn.p+portGasOut.p)/2;
        medium.T = 0.5*(mediumIn.T+mediumOut.T);
        medium.Xi = inStream(portGasIn.Xi_outflow);

        mediumIn.p  = portGasIn.p;
        mediumOut.p  = portGasOut.p;
        m_flowGas*hydraulicResistance_gas = portGasIn.p - portGasOut.p; // gas pressure drop

        m_flowGas = portGasIn.m_flow;
        portGasIn.m_flow + portGasOut.m_flow = 0;

        mediumIn.h = inStream(portGasIn.h_outflow);
        mediumIn.Xi  = medium.Xi;
        mediumOut.Xi = medium.Xi;

        portGasIn.h_outflow = mediumOut.h;
        portGasOut.h_outflow = mediumOut.h;

        portGasIn.Xi_outflow = inStream(portGasOut.Xi_outflow);
        portGasOut.Xi_outflow = inStream(portGasIn.Xi_outflow);

        VGas=geoFGZ.Lh*geoFGZ.Lw*(geoFGZ.Ld-geoPipe.L*geoPipe.d_out/geoFGZ.pt);
         m_flowGas*(actualStream(portGasIn.h_outflow) - actualStream(portGasOut.h_outflow))+sum(heatPortToWall.Q_flow +Q_flowToAmbient) =
               VGas*mediumOut.d*der(mediumOut.h);

       Q_flowToAmbient = heatPortToWall.Q_flow*heatloss/100.0;

       for i in 1:numberOfTubeNodes loop

        dT[i] = TWall[i] - 0.5*(mediumOut.T+mediumIn.T);

      heatPortToWall.Q_flow[i]=cleanliness*heatTransfer.heatingSurfaceFactor*heatTransfer.alpha[i]*Ah/numberOfTubeNodes*dT[i];
        end for;

        connect(tube.portIn, portIn) annotation (Line(points={{-2,-6},{-2,-43.25},{0,
                -43.25},{0,-80}},            color={0,127,255}));
        connect(tube.portOut, portOut) annotation (Line(points={{-2,14},{-2,44.35},{0,
                44.35},{0,80}},    color={0,127,255}));
        connect(heatPortToWall.port, tube.gasSide) annotation (Line(points={{-52,-12},
                {-52,4},{-8.6,4}},      color={191,0,0}));

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},
                  {100,100}}), graphics={Text(
                extent={{-72,24},{76,-16}},
                lineColor={0,0,0},
                textString=\"%name\")}),            Diagram(coordinateSystem(
                preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
        Documentation(
           info=\"<HTML>
        <p>
           This is a flue gas zone including a single water/steam tube as basis component for higher level flue gas zones  <br>
The flue gas flows perpendicular to the water/steam
          <ul>
               <li> The gas flow is modeled using a simple quasi stationary pressure drop.
               <li> The water/steam flow and inner heat transfer is modeled using the <bf>Components.Pipes.Tube</bf> model.
               <li> The outer heat transfer gas-metal can be chosen from
                    <ul>
                       <li> Escoa correlation, see <i>Chris Weierman, Correlations ease the selection"
         + " of finned tubes, The Oil and Gas Journal, Sept. 6, 1976</i>;
                            Update (Fintube Corp. <a href=\\\"http://www.fintubetech.com/escoa/manual.exe\\\">ESCOA Engineering Manual</a>) from July 2002.
                       <li> Simple heat transfer with constant heat transfer coefficient.
                    </ul>
          </ul>
<p>
           The model restrictions are:
                <ul>
                        <li> Cross flow configurations (gas flow is perpendicular to water/steam flow)
                </ul>
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
     </HTML>\",
           revisions=\"<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>\"));
      end FlueGasZoneSingleTubeOwnMedia;

      package Tests \"Tests for FlueGasZones\"
            // within SiemensPower.Components.FlueGasZones.Tests;

        model FlueGasZoneSingleTube_test
          \"Test case for the basic flue gas zone\"
          extends Modelica.Icons.Example;
          SiemensPower.Components.FlueGasZones.FlueGasZoneSingleTubeOwnMedia
            flueGasZoneSingleCompGas(
            geoFGZ(
              pt=0.085,
              Lw=7.3,
              Ld=13.5,
              Lh=0.4,
              Nr=4,
              pl=0.100),
            geoPipe(
              L=20,
              Nt=84,
              d_out=0.036,
              zeta_add=2),
            geoFins(
              serrated=false,
              h=0.019,
              s=0.0012,
              n=200,
              material=\"15 Mo 3\"),
            numberOfTubeNodes=
              20,
            m_flow_start=
                    18,
            hIn_start=
               1300e3,
            hOut_start=
               1700e3,
            m_flowGas_start=
                       200,
            heatloss=0.5,
            numberOfWallLayers=
                  3,
            redeclare package GasMedium =
                SiemensPower.Media.ExhaustGasSingleComponent,
            pIn_start=8200000,
            pOut_start=8200000,
            TGasIn_start=673,
            TGasOut_start=760,
            redeclare
              SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha
              heatTransfer)
                         annotation (Placement(transformation(extent={{-2,36},{18,56}},
                  rotation=0)));

          SiemensPower.Boundaries.GasSinkP gasSinkP(redeclare package Medium =
                SiemensPower.Media.ExhaustGasSingleComponent)
                                               annotation (Placement(transformation(
                  extent={{50,36},{70,56}}, rotation=0)));
          SiemensPower.Boundaries.GasSource gasSourceW(
            m_flow_start=
                    200,
            T_start=
               673.15,
            redeclare package Medium =
                SiemensPower.Media.ExhaustGasSingleComponent)
                         annotation (Placement(transformation(extent={{-54,36},{-34,56}},
                  rotation=0)));
          SiemensPower.Boundaries.WaterSink watersink_ph(
                                               p_start=
                                                  8200000)
            annotation (Placement(transformation(extent={{30,76},{50,96}}, rotation=0)));
          SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                                   m_flow_start=
                                                           18.41, h_start=
                                                                     1300e3)
            annotation (Placement(transformation(extent={{-34,-4},{-14,16}},   rotation=
                   0)));
          SiemensPower.Blocks.TimeTable timeTable(timeDelay=1, table=[0,673.15; 10,673.15; 100,773.15;
                200,773.15]) annotation (Placement(transformation(extent={{-82,72},{-62,
                    92}}, rotation=0)));
          SiemensPower.Components.FlueGasZones.FlueGasZoneSingleTubeOwnMedia
            flueGasZoneComposedGas(
            geoFGZ(
              pt=0.085,
              Lw=7.3,
              Ld=13.5,
              Lh=0.4,
              Nr=4,
              pl=0.100),
            geoPipe(
              L=20,
              Nt=84,
              d_out=0.036,
              zeta_add=2),
            geoFins(
              serrated=false,
              h=0.019,
              s=0.0012,
              n=200,
              material=\"15 Mo 3\"),
            numberOfTubeNodes=
              20,
            m_flow_start=
                    18,
            hIn_start=
               1300e3,
            hOut_start=
               1700e3,
            m_flowGas_start=
                       200,
            heatloss=0.5,
            numberOfWallLayers=
                  3,
            redeclare package GasMedium = SiemensPower.Media.ExhaustGas,
            pIn_start=8200000,
            pOut_start=8200000,
            TGasIn_start=673,
            TGasOut_start=760,
            redeclare
              SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha
              heatTransfer)
                         annotation (Placement(transformation(extent={{-12,-60},{8,-40}},
                  rotation=0)));
          SiemensPower.Boundaries.GasSinkP gasSinkP1(redeclare package Medium
              = SiemensPower.Media.ExhaustGas) annotation (Placement(transformation(
                  extent={{40,-60},{60,-40}},
                                            rotation=0)));
          SiemensPower.Boundaries.GasSource gasSourceW1(
            m_flow_start=
                    200,
            T_start=
               673.15,
            redeclare package Medium = SiemensPower.Media.ExhaustGas)
                         annotation (Placement(transformation(extent={{-64,-60},{-44,
                    -40}},
                  rotation=0)));
          SiemensPower.Boundaries.WaterSink watersink_ph1(
                                                p_start=
                                                   8200000)
            annotation (Placement(transformation(extent={{20,-20},{40,0}}, rotation=0)));
          SiemensPower.Boundaries.WaterSourceMH watersource_mh1(
                                                   m_flow_start=
                                                           18.41, h_start=
                                                                     1300e3)
            annotation (Placement(transformation(extent={{-44,-100},{-24,-80}},rotation=
                   0)));
        equation
          connect(gasSourceW.port,flueGasZoneSingleCompGas.portGasIn)
                                                                    annotation (Line(
              points={{-34,46},{-2,46}},
              color={0,191,0},
              smooth=Smooth.None));
          connect(flueGasZoneSingleCompGas.portGasOut, gasSinkP.portGas)
                                                                  annotation (Line(
              points={{18,46},{50,46}},
              color={0,191,0},
              smooth=Smooth.None));
          connect(watersource_mh.port,flueGasZoneSingleCompGas.portIn)
                                                                     annotation (Line(
              points={{-14,6},{8,6},{8,38}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(watersink_ph.port,flueGasZoneSingleCompGas.portOut)
                                                                   annotation (Line(
              points={{30,86},{8,86},{8,54}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(timeTable.y,gasSourceW.T_set) annotation (Line(points={{-61,82},{-44,
                  82},{-44,52}}, color={0,0,127}));
          connect(gasSourceW1.port,flueGasZoneComposedGas.portGasIn)
                                                                    annotation (Line(
              points={{-44,-50},{-12,-50}},
              color={0,191,0},
              smooth=Smooth.None));
          connect(flueGasZoneComposedGas.portGasOut, gasSinkP1.portGas)
                                                                  annotation (Line(
              points={{8,-50},{40,-50}},
              color={0,191,0},
              smooth=Smooth.None));
          connect(watersource_mh1.port,flueGasZoneComposedGas.portIn)
                                                                     annotation (Line(
              points={{-24,-90},{-2,-90},{-2,-58}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(watersink_ph1.port,flueGasZoneComposedGas.portOut)
                                                                   annotation (Line(
              points={{20,-10},{-2,-10},{-2,-42}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(timeTable.y,gasSourceW1.T_set) annotation (Line(" + "
              points={{-61,82},{-54,82},{-54,-44}},
              color={0,0,127},
              smooth=Smooth.None));
          annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                    -100},{100,100}}),
                              graphics),
        Documentation(
             info=\"<HTML>
        <p>
           This is a test case for the basic flue gas zone with a single tube in a cross flow flue gas zone.
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
     </HTML>\",
             revisions=\"<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>\"),
            experiment(StopTime=200),
            Commands(file=\"Scripts/tests/FlueGasZoneSingleTube_test.mos\"
                \"FlueGasZoneSingleTube_test\"));
        end FlueGasZoneSingleTube_test;
      annotation (Documentation(info=\"<html>
This package contains tests.
</html>\"));
      end Tests;
    annotation (Documentation(info=\"<html>
This package contains flue gas zones.
</html>\"));
    end FlueGasZones;

    package HeatExchanger
      \"Simple heat exchangers and compositions of tubes and flue gas zones\"
      model ParallelFlowEvaporatorOwnMedia
        \"Evaporator with parallel rows according to Cottam design\"
        import SI = SiemensPower.Units;
        replaceable package GasMedium =  SiemensPower.Media.ExhaustGas constrainedby
          Modelica.Media.Interfaces.PartialMedium \"Flue gas medium\"
            annotation (   choicesAllMatching=true, Dialog(group=\"Media\"));

        replaceable package WaterMedium = Modelica.Media.Water.WaterIF97_ph
          constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium
          \"Water/steam medium\"                            annotation (choicesAllMatching=
              true, Dialog(group=\"Media\"));

        parameter Integer numberOfTubeLayers(min=1)=1 \"Number of tube layers\";
        parameter Integer numberOfCellsPerLayer=20
          \"Number of water/steam cells per tube layer\";
        parameter Integer numberOfWallLayers(min=1)=3 \"Number of wall layers\" annotation(choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
        parameter SiemensPower.Utilities.Structures.FgzGeo geoFGZ(
            pt=0.085,
            pl=0.09,
            Lw=3.6,
            Ld=21,
            Lh=0.09,
            Nr=14,
            staggered=true) \"Geometry of flue gas zone\"  annotation (Dialog(group=\"Geometry\"));
         parameter SiemensPower.Utilities.Structures.Fins geoFins(
            h=0.016,
            s=0.001,
            n=294,
            finned=true,
            w=0.0044,
            serrated=true) \"Geometry of outer wall fins\" annotation (Dialog(group=\"Geometry\"));
         parameter SiemensPower.Utilities.Structures.PropertiesMetal
          propertiesMetal \"Tube wall properties\"                                         annotation (Dialog(group=\"Media\"));
         parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe(
            Nt=40,
            L=21,
            H=21,
            d_out=0.0381,
            s=0.00325,
            zeta_add=0.75) \"Geometry of tubes\" annotation (Dialog(group=\"Geometry\"));

        parameter Real cleanlinessFactor=1.0;
        parameter Real heatloss=0.5 \"Heat loss to ambient in %\";
        parameter Boolean hasMixerVolume=false annotation(Dialog(group=\"Mixer\"));
        parameter SI.Volume V=0.1 annotation(Dialog(group=\"Mixer\", enable=hasMixerVolume));
        parameter Modelica.Fluid.Types.HydraulicResistance
          hydrResistanceSplitterOut =                                                2000
          \"Hydraulic conductance\" annotation(Dialog(group=\"Splitter\", enable=withPressureDrops));

        parameter SiemensPower.Units.MassFlowRate m_flowGas_start=228.68
          \"Flue gas mass flow rate\" annotation (Dialog(tab=\"Initialization\", group=\"Flue gas flow\"));
        parameter GasMedium.Temperature TGasIn_start=390
          \"Inlet gas temperature\"
          annotation (Dialog(tab=\"Initialization\", group=\"Flue gas flow\"));
        parameter GasMedium.Temperature TGasOut_start=TGasIn_start
          \"Outlet gas temperature\"
          annotation (Dialog(tab=\"Initialization\", group=\"Flue gas flow\"));
        parameter SiemensPower.Units.MassFlowRate m_flow_start=19.05
          \"Total water/steam mass flow rate\" annotation (Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter GasMedium.AbsolutePressure pIn_start=pOut_start+2e5
          \"start value for inlet pressure\"                            annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter GasMedium.AbsolutePressure pOut_start=137e5
          \"start value for outlet pressure\"                              annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter GasMedium.SpecificEnthalpy hIn_start=500e3
          \"start value for inlet enthalpy\"                                      annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));
        parameter GasMedium.SpecificEnthalpy hOut_start=hIn_start
          \"start value for outlet enthalpy\"                                   annotation(Dialog(tab=\"Initialization\", group=\"Water flow\"));

        replaceable model outerHeatTransfer =
            SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha constrainedby
          SiemensPower.Utilities.HeatTransfer.HeatTransferBaseClass
          \"Convective heat transfer\"
                  annotation (Dialog(tab=\"Heat transfer\", group=\"Outer heat transfer\"),editButton=true,choicesAllMatching);

        SiemensPower.Components.FlueGasZones.FlueGasZoneSingleTubeOwnMedia[numberOfTubeLayers]
          flueGasZone(
            redeclare each package GasMedium = GasMedium,
          each numberOfTubeNodes=
                 numberOfCellsPerLayer,
          each numberOfWallLayers=
                     numberOfWallLayers,
          each geoPipe=
                    geoPipe,
          each m_flowGas_start=
                          m_flowGas_start,
          each TGasIn_start= TGasIn_start,
          each TGasOut_start=TGasOut_start,
          each cleanliness=cleanlinessFactor,
          each hydraulicResistance_gas=
                 0.3,
          each geoFins=
                   geoFins,
          each geoFGZ=
                   geoFGZ,
          each metal=propertiesMetal,
          each heatloss=heatloss,
          each m_flow_start=
                       m_flow_start/numberOfTubeLayers,
          each pIn_start=
                  pIn_start,
          each pOut_start=
                  pOut_start,
          each hIn_start=
                  hIn_start,
          each hOut_start=
                  hOut_start,
          redeclare package H2OMedium = WaterMedium,
          redeclare SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha
            heatTransfer)
          annotation (extent=[-10,-10; 10,10]);

        SiemensPower.Components.Junctions.SplitterMixer splitter(
          V=0.1*(numberOfTubeLayers+1),
          h_start=hIn_start,
          hasVolume=false,
          p_start=pIn_start,
          hasPressureDrop=true,
          numberOfPortsSplit=numberOfTubeLayers,
          m_flow_start=m_flow_start,
          redeclare package Medium = WaterMedium,
          resistanceHydraulic=hydrResistanceSplitterOut)           annotation (extent=[-10,-50; 10,-30]);
        SiemensPower.Components.Junctions.SplitterMixer mixer(
          h_start=hOut_start,
          resistanceHydraulic=2,
          hasPressureDrop=false,
          p_start=pOut_start,
          numberOfPortsSplit=numberOfTubeLayers,
          m_flow_start=-m_flow_start,
          redeclare package Medium = WaterMedium,
          hasVolume=hasMixerVolume,
          V=V,
          initializeSteadyEnthalpyBalance=false)
                          annotation (extent=[-10,60; 12,36]);

        Modelica.Fluid.Interfaces.FluidPort_b portSteamOut(redeclare package
            Medium =
              WaterMedium)
          annotation (extent=[20,80; -20,120]);
        Modelica.Fluid.Interfaces.FluidPort_a portWaterIn(redeclare package
            Medium =
              WaterMedium)
          annotation (extent=[-20,-120; 20,-80]);
        SiemensPower.Interfaces.portGasOut portGasOut(
                                                     redeclare package Medium
            =                                                                   GasMedium, m_flow(start=-m_flowGas_start)) annotation (extent=[80,-20;
              120,20]);
        SiemensPower.Interfaces.portGasIn portGasIn(redeclare package Medium = GasMedium, m_flow(start=m_flowGas_start))
          annotation (extent=[-120,-20; -80,20]);
      equation

        connect(flueGasZone[1].portGasIn,portGasIn)
          annotation (points=[-10,0; -100,0],style(color=58, rgbcolor={0,191,0}));
        for i in 1:(numberOfTubeLayers" + "-1) loop
            connect(flueGasZone[i].portGasOut,flueGasZone[i + 1].portGasIn);
        end for;
        connect(flueGasZone[numberOfTubeLayers].portGasOut,
                                           portGasOut) annotation (points=[10,0; 100,0],
                           style(color=58, rgbcolor={0,191,0}));
        connect(splitter.portMix, portWaterIn)
          annotation (points=[0,-49; 0,-100],style(color=69, rgbcolor={0,127,255}));
        connect(mixer.portMix, portSteamOut) annotation (points=[1,58.8; 1,58.4; 0,58.4;
              0,100],       style(color=69, rgbcolor={0,127,255}));
        connect(flueGasZone.portIn,splitter.portsSplit) annotation (points=[0,-8; 0,-31],
            style(
            color=69,
            rgbcolor={0,127,255},
            fillColor=1,
            rgbfillColor={255,0,0},
            fillPattern=1));
        connect(mixer.portsSplit,flueGasZone.portOut) annotation (points=[1,37.2; 1,22.6;
              0,22.6; 0,8], style(
            color=69,
            rgbcolor={0,127,255},
            fillColor=1,
            rgbfillColor={255,0,0},
            fillPattern=1));
        annotation (uses(Modelica(version=\"2.2.1\"), SiemensPower(version=\"0.9\")),
            Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
                  100}}),     graphics),
          Icon(
            Rectangle(extent=[-64,60; -54,-60], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[-24,60; -14,-60], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[16,60; 26,-60], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[54,60; 64,-60], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[-64,-70; 64,-60], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[-64,60; 64,70], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[-4,80; 6,70], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Rectangle(extent=[-4,-70; 6,-80], style(
                pattern=0,
                fillColor=69,
                rgbfillColor={0,128,255})),
            Polygon(points=[-80,4; -68,4; -68,8; -64,0; -68,-6; -68,-2; -80,-2; -80,4],
                style(
                color=1,
                rgbcolor={255,0,0},
                arrow=1,
                fillColor=1,
                rgbfillColor={255,0,0},
                fillPattern=1)),
            Polygon(points=[-46,4; -34,4; -34,8; -30,0; -34,-6; -34,-2; -46,-2; -46,4],
                style(
                color=1,
                rgbcolor={255,0,0},
                arrow=1,
                fillColor=1,
                rgbfillColor={255,0,0},
                fillPattern=1)),
            Polygon(points=[-6,4; 6,4; 6,8; 10,0; 6,-6; 6,-2; -6,-2; -6,4], style(
                color=1,
                rgbcolor={255,0,0},
                arrow=1,
                fillColor=1,
                rgbfillColor={255,0,0},
                fillPattern=1)),
            Polygon(points=[34,4; 46,4; 46,8; 50,0; 46,-6; 46,-2; 34,-2; 34,4], style(
                color=1,
                rgbcolor={255,0,0},
                arrow=1,
                fillColor=1,
                rgbfillColor={255,0,0},
                fillPattern=1)),
            Polygon(points=[66,4; 76,4; 76,8; 80,0; 76,-6; 76,-2; 66,-2; 66,4], style(
                color=1,
                rgbcolor={255,0,0},
                arrow=1,
                fillColor=1,
                rgbfillColor={255,0,0},
                fillPattern=1))),
      Documentation(
           info=\"<HTML>
        <p>
           This is an evaporator with parallel rows according to Cottam design
          <ul>
               <li> The gas flow is modeled using a simple quasi stationary pressure drop.
               <li> The water/steam flow and inner heat transfer is modeled using the <bf>Components.Pipes.Tube</bf> model.
               <li> The outer heat transfer gas-metal can be chosen from
                    <ul>
                       <li> Escoa correlation, see <i>Chris Weierman, Correlations ease the selection of finned tubes, The Oil and Gas Journal, Sept. 6, 1976</i>;
                            Update (Fintube Corp. <a href=\\\"http://www.fintubetech.com/escoa/manual.exe\\\">ESCOA Engineering Manual</a>) from July 2002.
                       <li> Simple heat transfer with constant heat transfer coefficient.
                    </ul>
          </ul>
<p>
           The model restrictions are:
                <ul>
                        <li> see composits
                </ul>
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
     </HTML>\",
           revisions=\"<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>\"));
      end ParallelFlowEvaporatorOwnMedia;

      package Tests \"Tests for HeatExchanger\"
            // within SiemensPower.Components.HeatExchanger.Tests;

        model ParallelFlowEvaporatorOwnMedia_test
          \"Evaporator of Liegender Benson with parallel gas and water flow, with analytical Jacobian\"

           parameter Integer N=2 \"Number of water/steam cells per tube layer\";

          SiemensPower.Components.HeatExchanger.ParallelFlowEvaporatorOwnMedia
            EVA1(
            geoPipe(
                 s=0.00264, Nt=130),
            propertiesMetal(
                  lambda=40),
            geoFins(
              h=0.019,
              s=0.00125,
              n=300,
              material=\"St 35.8\"),
            geoFGZ(
                pt=0.09, Lh=0.18),
            redeclare package GasMedium =
                SiemensPower.Media.ExhaustGasSingleComponent,
            V=1,
            hasMixerVolume=
                       false,
            hydrResistanceSplitterOut=
              7000,
            numberOfCellsPerLayer=
              N,
            numberOfWallLayers=
                  1,
            numberOfTubeLayers=
               2)
            annotation (Placement(transformation(extent={{20,22},{40,42}}, rotation=0)));

          SiemensPower.Components.HeatExchanger.ParallelFlowEvaporatorOwnMedia
            EVA2(
            geoFins(
                material=\"13 CrMo 4.4\"),
            propertiesMetal(
                  lambda=38),
            redeclare package GasMedium =
                SiemensPower.Media.ExhaustGasSingleComponent,
            V=1,
            hasMixerVolume=
                       false,
            hydrResistanceSplitterOut=
              3000,
            numberOfCellsPerLayer=
              N,
            numberOfWallLayers=
                  1,
            numberOfTubeLayers=
               2)
            annotation (Placement(transformation(extent={{-24,22},{-4,42}}, rotation=0)));

          SiemensPower.Components.Pipes.TubeOwnMedia downcomer(
            geoPipe(
              Nt=2,
              L=26,
              H=-21,
              d_out=0.1683,
              s=0.01427,
              zeta_add=0.5),
            hIn_start= 500e3,
            hOut_start= 500e3,
            considerDynamicPressure=
                         false,
            useDelayedPressure=
                          false,
            m_flow_start=
                    20,
            numberOfNodes=
              N,
            useINTH2O=
                   false,
            pIn_start= 13700000,
            pOut_start= 13900000)
                 annotation (Placement(transformation(
                origin={5,14},
                extent={{-12,-9},{8,9}},
                rotation=270)));
          SiemensPower.Boundaries.WaterSink watersink_ph
            annotation (Placement(transformation(extent={{-14,78},{6,98}}, rotation=0)));
          SiemensPower.Boundaries.WaterSourceMH watersource_mh
            annotation (Placement(transformation(extent={{82,-4},{60,-26}},  rotation=0)));
          SiemensPower.Blocks.Smoothing smoothing(timeDelay=
                                                    0.01) annotation (Placement(
                transformation(extent={{-80,-18},{-60,2}},   rotation=0)));
          SiemensPower.Blocks.Smoothing smoothing1(timeDelay=
                                                     0.01) annotation (Placement(
                transformation(extent={{-80,-4},{-60,16}},   rotation=0)));
          SiemensPower.Blocks.Smoothing smoothing2(timeDelay=
                                                     0.01) annotation (Placement(
         " + "       transformation(extent={{-80,-38},{-60,-18}}, rotation=0)));
          Modelica.Fluid.Sources.MassFlowSource_h massflowSource_h(
            nPorts=1,
            use_m_flow_in=true,
            use_h_in=true,
            redeclare package Medium =
                SiemensPower.Media.ExhaustGasSingleComponent,
            use_X_in=false)
            annotation (Placement(transformation(extent={{-74,22},{-54,42}})));
          Modelica.Fluid.Sources.Boundary_ph boundary_ph(
            nPorts=1,
            redeclare package Medium =
                SiemensPower.Media.ExhaustGasSingleComponent,
            use_p_in=true,
            use_h_in=true,
            use_X_in=false)
            annotation (Placement(transformation(extent={{70,24},{54,40}})));
          SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                                          N)
            annotation (Placement(transformation(extent={{-8,-8},{10,8}},
                rotation=90,
                origin={24,0})));
          Modelica.Blocks.Sources.RealExpression realExpression
            annotation (Placement(transformation(extent={{-2,-20},{10,-8}})));
          Modelica.Fluid.Sensors.MassFlowRate massFlowRate(redeclare package
              Medium =
                Modelica.Media.Water.StandardWater) annotation (Placement(
                transformation(
                extent={{-8,9},{9,-8}},
                rotation=90,
                origin={-14,59})));
          Modelica.Fluid.Sensors.Temperature temperature(redeclare package
              Medium =
                Modelica.Media.Water.StandardWater)
            annotation (Placement(transformation(extent={{-44,64},{-28,84}})));
          Modelica.Fluid.Sensors.Pressure pressure(redeclare package Medium =
                Modelica.Media.Water.StandardWater)
            annotation (Placement(transformation(extent={{50,-2},{70,16}})));
          Modelica.Blocks.Interfaces.RealOutput ausgang[3] \"pin mout Tout\"
            annotation (Placement(transformation(extent={{90,50},{110,70}})));
          inner Modelica.Fluid.System system
            annotation (Placement(transformation(extent={{-72,84},{-60,96}})));
          SiemensPower.Blocks.TimeTable h_in_gas(timeDelay=
                                                      0.5, table=[0,121.894e3; 10,
                121.894e3; 900,537.432e3; 1000,537.432e3])
                             annotation (Placement(transformation(extent={{-108,26},{
                    -88,46}},
                          rotation=0)));
          Modelica.Blocks.Sources.RealExpression p_out_gas(y=1.01325e5)
            annotation (Placement(transformation(extent={{-108,60},{-88,80}},rotation=0)));
          Modelica.Blocks.Sources.RealExpression hr_gas(y=122e3)
            annotation (Placement(transformation(extent={{-108,74},{-88,94}},rotation=0)));
          Modelica.Blocks.Sources.RealExpression m_in_gas(y=228.68)
            annotation (Placement(transformation(extent={{-108,46},{-88,66}},
                                                                            rotation=0)));
          SiemensPower.Blocks.TimeTable h_in_water(timeDelay=
                                                        1, table=[0,500e3; 100,500e3;
                2000,1527e3; 3000,1527e3])
                             annotation (Placement(transformation(extent={{-108,-38},{
                    -88,-18}},
                           rotation=0)));
          Modelica.Blocks.Sources.RealExpression hr_water(y=2800e3)
            annotation (Placement(transformation(extent={{-108,-4},{-88,16}},
                                                                            rotation=0)));
          Modelica.Blocks.Sources.RealExpression p_out_water(y=137.058e5)
            annotation (Placement(transformation(extent={{-108,-18},{-88,2}},rotation=0)));
          Modelica.Blocks.Sources.RealExpression m_in_water(y=20)
            annotation (Placement(transformation(extent={{-108,-58},{-88,-38}},
                                                                             rotation=0)));
        equation

          connect(EVA2.portGasOut,EVA1.portGasIn)
            annotation (Line(points={{-4,32},{20,32}}, color={0,191,0}));
          connect(EVA1.portSteamOut,downcomer.portIn)   annotation (Line(points={{30,42},
                  {30,50},{5,50},{5,26}},           color={0,127,255}));
          connect(downcomer.portOut,
                                   EVA2.portWaterIn)   annotation (Line(points={{5,6},{5,
                  0},{-14,0},{-14,22}},                 color={0,127,255}));
          connect(smoothing1.y,watersink_ph.h_set)       annotation (Line(points={{-65,6},
                  {-48,6},{-48,102},{0,102},{0,96}},      color={0,0,127}));
          connect(smoothing2.y,watersource_mh.hIn)         annotation (Line(points={{-65,-28},
                  {66,-28},{66,-21.6},{66.6,-21.6}},                   color={0,0,127}));
          connect(watersource_mh.port,EVA1.portWaterIn)     annotation (Line(points={{60,-15},
                  {30,-15},{30,22}},                 color={0,127,255}));
          connect(massflowSource_h.ports[1],EVA2.portGasIn)
                                                     annotation (Line(
              points={{-54,32},{-24,32}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(EVA1.portGasOut,boundary_ph.ports[1])
                                                      annotation (Line(
              points={{40,32},{54,32}},
              color={0,191,0},
              smooth=Smooth.None));
          connect(downcomer.gasSide,prescribedHeatFlow.portsOut)
                                                              annotation (Line(
              points={{10.94,16},{24,16},{24,10}},
              color={191,0,0},
              smooth=Smooth.None));
          connect(prescribedHeatFlow.Q_flow, realExpression.y) annotation (Line(
              points={{24,-8},{24,-14},{10.6,-14}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(watersink_ph.port, massFlowRate.port_b)       annotation (Line(
              points={{-14,88},{-14.5,88},{-14.5,68}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(massFlowRate.port_a,EVA2.portSteamOut)
                                                       annotation (Line(
              points={{-14.5,51},{-14.5,42},{-14,42}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(temperature.port,EVA2.portSteamOut)
                                                    annotation (Line(
              points={{-36,64},{-36,42},{-14,42}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(pressure.port, watersource_mh.port)       annotation (Line(
              points={{60,-2},{60,-15}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(h_in_gas.y, massflowSource_h.h_in)
                                             annotation (Line(
              points={{-87,36},{-76,36}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(m_in_gas.y, massflowSource_h.m_flow_in)
                                                  annotation (Line(
              points={{-87,56},{-84,56},{-84,40},{-74,40}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(hr_water.y, smoothing1.u) annotation (Line(
              points={{-87,6},{-79,6}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(p_out_water.y, smoothing.u) annotation (Line(
              points={{-87,-8},{-79,-8}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(h_in_water.y, smoothing2.u) annotation (Line(
              points={{-87,-28},{-79,-28}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(m_in_water.y,watersource_mh.m_flowIn)       annotation (Line(
              points={{-87,-48},{76,-48},{76,-21.6},{75.4,-21.6}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(smoothing.y,watersink_ph.p_set)       annotation (Line(
              points={{-65,-8},{-46,-8},{-46,100},{-8,100},{-8,96}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(p_out_gas.y, boundary_ph.p_in)
                                               annotation (Line(
              points={{-87,70},{-80,70},{-80,106},{78,106},{78,38.4},{71.6,38.4}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(hr_gas.y, boundary_ph.h_in)
                                            annotation (Line(
              points={{-87,84},{-82,84},{-82,108},{80,108},{80,36},{71.6,36},{71.6,35.2}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(pressure.p, ausgang[1]) annotation (Line(
              points={{71,7},{88,7},{88,53.3333},{100,53.3333}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(temperature.T, ausgang[3]) annotation (Line(
              points={{-30.4,74},{88,74},{88,66.6667},{100,66.6667}},
              color={0,0,127},
              smooth=Smooth.None));
          connect(massFlowRate.m_flow, ausgang[2]) annotation (Line(
              points={{-5.15,59.5},{93.95,59.5},{93.95,60},{100,60}},
              color={0,0,127},
              smooth=Smooth.None));
          annotation (uses(Modelica(version=\"2.2.1\"), SiemensPower(version=\"0.9\")),
              Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-110,-55},{
                    110,110}}), graphics={Text(
                  extent={{-10,46},{0,38}},
                  lineColor={255,0,0},
                  textString=\"EVA1\"), Text(
                  extent={{34,46},{44,38}},
                  li" + "neColor={255,0,0},
                  textString=\"EVA2\")}),
            Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-110,-55},{110,
                    110}}), graphics={
                Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,0}),
                Ellipse(
                  extent={{-34,-90},{26,-66}},
                  lineColor={255,255,255},
                  fillColor={0,128,255},
                  fillPattern=FillPattern.Solid),
                Ellipse(
                  extent={{-20,-72},{-16,-76}},
                  lineColor={255,255,255},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Ellipse(
                  extent={{4,-80},{8,-84}},
                  lineColor={255,255,255},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid)}),
            Documentation(info=\"<HTML>
        <p>
           This is a test case for CouterCurrentHeatExchanger
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:yongqi.sun@siemens.com\\\">Yongqi Sun</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2008 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
     </HTML>\"));
        end ParallelFlowEvaporatorOwnMedia_test;
      annotation (Documentation(info=\"<html>
This package contains tests.
</html>\"));
      end Tests;
    annotation (Documentation(info=\"<html>
This package contains heat exchangers.
</html>\"));
    end HeatExchanger;

    package Junctions
      \"Contains splitter, mixer, separators without volume and decouple elements\"
      model SplitterMixer \"Splitter/mixer with N ports\"

        import SI = SiemensPower.Units;
        //replaceable package Medium = Modelica.Media.Water.WaterIF97_ph constrainedby
        //  Modelica.Media.Interfaces.PartialMedium \"Medium in the component\"  annotation (
        //    choicesAllMatching =      true);

        parameter Integer numberOfPortsSplit(min=1)=2
          \"Number of inlets(mixer) / outlets(splitter)\";

        parameter SI.AbsolutePressure p_start=1e5 \"Pressure\"
                                                     annotation(Dialog(tab=\"Initialization\"));
        parameter Boolean useTemperatureStartValue=false
          \"Use temperature instead of specific enthalpy\"                                   annotation(Dialog(tab=\"Initialization\"));
        // parameter Medium.SpecificEnthalpy h_start=if useTemperatureStartValue then Medium.specificEnthalpy_pTX(p_start, T_start, Medium.reference_X) else 300e3
       parameter SI.SpecificEnthalpy h_start = 300e3 \"Specific enthalpy\"
        annotation(Dialog(tab=\"Initialization\", enable= not useTemperatureStartValue));
       // parameter Medium.Temperature T_start=
       //     if useTemperatureStartValue then 300 else Medium.temperature_phX(p_start,h_start,Medium.reference_X)
         parameter SI.Temperature T_start=300 \"Guess value of temperature\"
         annotation(Dialog(tab = \"Initialization\", enable = useTemperatureStartValue));
        //parameter SI.MassFraction X_start[Medium.nX] = Medium.reference_X
        //  \"Start value of mass fractions m_i/m\"
        //  annotation (Dialog(tab=\"Initialization\", enable=Medium.nXi > 0));

        parameter SI.MassFlowRate m_flow_start=1
          \"Mass flow rate trough outlet(mixer, negative!) / inlet(splitter)\"                                   annotation(Dialog(tab=\"Initialization\"));
        parameter SI.MassFlowRate[numberOfPortsSplit] m_flowOpposite_start = -ones(numberOfPortsSplit)*m_flow_start/numberOfPortsSplit
          \"Mass flow rate trough inlets(mixer) / outlets(splitter, negative!)\"                                   annotation(Dialog(tab=\"Initialization\"));

        parameter Boolean initializeSteadyMassBalance=true \"ma=sum(mb)\" annotation(Dialog(tab=\"Initialization\",group=\"Initial equations in case of volume > 0\", enable=hasVolume));
        parameter Boolean initializeSteadyEnthalpyBalance=true
          \"der(h)=0, may be too much in case of mixer\"
                       annotation(Dialog(tab=\"Initialization\",group=\"Initial equations in case of volume > 0\", enable=hasVolume));
        parameter Boolean initializeFixedPressure=false \"p=p_start\" annotation(Dialog(tab=\"Initialization\",group=\"Initial equations in case of volume > 0\", enable=hasVolume));
        parameter Boolean initializeFixedEnthalpy=false \"h=h_start\" annotation(Dialog(tab=\"Initialization\",group=\"Initial equations in case of volume > 0\", enable=hasVolume));

        parameter Boolean hasVolume=false annotation(evaluate=true, Dialog(group=\"Volume\"));
        parameter SI.Volume V=0.1 annotation(Dialog(group=\"Volume\", enable=hasVolume));
        parameter Boolean hasPressureDrop=false
          \"may be necessary in case of a splitter\"                                         annotation(evaluate=true, Dialog(group=\"Pressure loss\"));
        parameter Modelica.Fluid.Types.HydraulicResistance resistanceHydraulic=2
          \"Hydraulic resistance\" annotation(Dialog(group=\"Pressure loss\", enable=hasPressureDrop));

        SI.SpecificEnthalpy h( start = h_start);
        SI.Pressure p( start = p_start);
        SI.Density d;

        SiemensPower.Interfaces.FluidPort_a portMix(
          m_flow(start=m_flow_start),
          p(start=p_start),
          h_outflow(start=h_start)) \"inlet(splitter) / outlet(mixer)\"                                              annotation (Placement(
              transformation(extent={{-10,-100},{10,-80}}, rotation=0)));
        //  redeclare package Medium = Medium,

        SiemensPower.Interfaces.FluidPorts_b portsSplit[numberOfPortsSplit](
          m_flow(start=m_flowOpposite_start),
          each p(start=p_start),
          each h_outflow(start=h_start)) \"outlets(splitter) / inlets(mixer)\"
          annotation (Placement(transformation(extent={{-8,16},{12,96}}),
              iconTransformation(
              extent={{-10,-40},{10,40}},
              rotation=90,
              origin={0,90})));
        //  redeclare package Medium = Medium,

      //  Medium.BaseProperties medium(h(start=h_start), p(start=p_start), X(start=X_start));

        SI.MassFlowRate m_flowFromPortMix;
        SI.MassFlowRate m_flowFromPortsSplit[ numberOfPortsSplit];

      initial equation

      if hasVolume then
         if (initializeSteadyEnthalpyBalance) then
           der(h) = 0;
         end if;
         if  initializeSteadyMassBalance then
            portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = 0;
         end if;
         if (initializeFixedPressure) then
            p = p_start;
         end if;
         if (initializeFixedEnthalpy) then
            h = h_start;
         end if;
      end if;

      equation

        d = SiemensPower.Media.TTSE.Utilities.rho_ph(p, h);
        if hasVolume then
          portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = V*der(d);
        else
          portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = 0;
        end if;

        if hasVolume then
           m_flowFromPortMix*(inStream(portMix.h_outflow)- h)  + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].h_outflow)- h)   for i in 1:numberOfPortsSplit) = V*d*der(h);
        else
           m_flowFromPortMix*(inStream(portMix.h_outflow)- h)   + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].h_outflow)- h)   for i in 1:numberOfPortsSplit) = 0;
        end if;

      //  if hasVolume then
      //     m_flowFromPortMix*(inStream(portMix.Xi_outflow)-medium.Xi) + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].Xi_outflow)-medium.Xi) for i in 1:numberOfPortsSplit) = V*d*der(medium.Xi);
      //  else
      //     m_flowFromPortMix*(inStream(portMix.Xi_outflow)-medium.Xi) + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].Xi_outflow)-medium.Xi) for i in 1:numberOfPortsSplit) = zeros(Medium.nXi);
      //  end if;

        portMix.p = p;
        portMix.h_outflow   = h;
      //  portMix.Xi_outflow = medium.Xi;

        m_flowFromPortMix=max(0,portMix.m_flow);

        for i in 1:numberOfPortsSplit loop
            if (hasPressureDrop) then
                portsSplit[i].p - p =resistanceHydraulic*portsSplit[i].m_flow;
            else
                portsSplit[i].p = p;
            end if;
            portsSplit[i].h_outflow = h;
          //  portsSplit[i].Xi_outflow = medium.Xi;
            m_flowFromPortsSplit [i]=max(0,portsSplit[i].m_flow);
        end for;

        annotation (Documentation(
       info=\"<HTML>
This splitter/mixer hasa variable number N of ports. It can be an ideal splitter/mixer (hasVolume=false and hasPressureDrop=false)
or can be modeled with a volume and/or pressure losses in the N outlets/inlets.
<p>
In case of using this component as a mixer you must use the portsSplit[numberOfPortsSplit] as inlets and portMix as the outlet.
<p>
<table>
        <tr>
              <td><b>Author:</b>  </td>
              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
              <t" + "d><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
       </tr>
        <tr>
           <td><b>Checked by:</b>   </td>
           <td>            </td>
        </tr>
        <tr>
           <td><b>Protection class:</b>    </td>
           <td>free </td>
        </tr>
        <tr>
           <td><b>Used Dymola version:</b>    </td>
           <td>6.1 </td>
        </tr>

        </table>
     Copyright &copy  2007 Siemens AG, PG EIP12 , All rights reserved.<br>
 <br>   This model is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY. For details <a href=\\\"../Documents/Disclaimer.html\\\">see</a> <br>
</HTML>\", revisions=\"<html>
                      <ul>
                              <li> Feb 2009 adapted for stream connector by Haiko Steuer
                              <li> November 2007, generalized for other media
                              <li> June 2007 by Haiko Steuer (for water/steam)
                       </ul>
                        </html>\"),
          Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
                  100}}),     graphics),
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics={Polygon(
                points={{-20,-80},{20,-80},{20,-20},{76,-20},{76,80},{46,80},{46,20},
                    {16,20},{16,80},{-16,80},{-16,20},{-44,20},{-44,80},{-76,80},{-76,
                    -20},{-20,-20},{-20,-80}},
                smooth=Smooth.None,
                pattern=LinePattern.None,
                lineColor={0,0,0},
                fillColor={0,128,255},
                fillPattern=FillPattern.Solid)}));
      end SplitterMixer;

      package Tests
            // within SiemensPower.Components.Junctions.Tests;

        model splitterMixer_test \"Test case for SplitterMixer\"
        //  extends Modelica.Icons.Example;

        SiemensPower.Components.Junctions.SplitterMixer splitter(
            hasPressureDrop = true,
            resistanceHydraulic=
              100,
            h_start=1000e3,
            numberOfPortsSplit=
              2,
            m_flow_start=
                    20,
            p_start=3000000)
                        annotation (Placement(transformation(extent={{-34,-52},{-14,-32}},
                  rotation=0)));
          SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                                   h_start=
                                                      1000e3, m_flow_start=
                                                                      20)
            annotation (Placement(transformation(extent={{-44,-86},{-24,-66}}, rotation=
                   0)));
          SiemensPower.Boundaries.WaterSink watersink_ph(  h_start=
                                                              1500e3, p_start=
                                                                         3000000)
            annotation (Placement(transformation(extent={{12,70},{32,90}},   rotation=0)));
          SiemensPower.Components.Junctions.SplitterMixer mixer(
            numberOfPortsSplit=
              3,
            h_start=1000e3,
            m_flow_start=
                    -30,
            useTemperatureStartValue=
                        true,
            hasVolume= true,
            V=0.05,
            initializeSteadyEnthalpyBalance=
                                  false,
            p_start=3000000)
                         annotation (Placement(transformation(extent={{-24,64},{-6,42}},
                  rotation=0)));

          SiemensPower.Components.Pipes.TubeWithoutWall pipe1(
                                    geoPipe(zeta_add=1),
            m_flow_start=
                    10,
            pIn_start= 3100000,
            pOut_start= 3000000,
            hIn_start= 1000e3,
            hOut_start= 1000e3)
            annotation (Placement(transformation(
                origin={-34,8},
                extent={{-10,-10},{10,10}},
                rotation=90)));
          SiemensPower.Components.Pipes.TubeWithoutWall pipe2(
                                    geoPipe(zeta_add=2),
           m_flow_start=
                   10,
            pIn_start= 3100000,
            pOut_start= 3000000,
            hIn_start= 1000e3,
            hOut_start= 1000e3)
            annotation (Placement(transformation(
                origin={-14,8},
                extent={{-10,-10},{10,10}},
                rotation=90)));
          SiemensPower.Components.Pipes.TubeWithoutWall pipe3(
           m_flow_start=
                   10,
            pIn_start= 3100000,
            pOut_start= 3000000,
            hIn_start= 2000e3,
            hOut_start= 2000e3)
                       annotation (Placement(transformation(
                origin={8,8},
                extent={{-10,-10},{10,10}},
                rotation=90)));
          SiemensPower.Boundaries.WaterSourceMH watersource_mh1(
                                                    h_start=
                                                       2000e3, m_flow_start=
                                                                       10)
            annotation (Placement(transformation(extent={{44,-40},{26,-22}},   rotation=
                   0)));
          SiemensPower.Blocks.TimeTable timeTable(table=[0,5; 1,5; 2,0; 3,0; 4,-10; 5,-10])
            annotation (Placement(transformation(extent={{86,8},{70,24}})));
        equation
          connect(watersource_mh.port,splitter.portMix) annotation (Line(
              points={{-24,-76},{-24,-51}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(mixer.portMix,watersink_ph.port) annotation (Line(
              points={{-15,62.9},{-15,80},{12,80}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(splitter.portsSplit[1],pipe1.portIn)
                                                    annotation (Line(
              points={{-24,-35},{-24,-32},{-34,-32},{-34,-2}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(splitter.portsSplit[2],pipe2.portIn)
                                                    annotation (Line(
              points={{-24,-31},{-24,-32},{-14,-32},{-14,-2}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(pipe1.portOut,
                               mixer.portsSplit[1])
                                                 annotation (Line(
              points={{-34,18},{-34,40},{-18,40},{-18,46.0333},{-15,46.0333}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(pipe2.portOut,
                               mixer.portsSplit[2])
                                                 annotation (Line(
              points={{-14,18},{-14,30.35},{-15,30.35},{-15,43.1}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(pipe3.portOut,
                               mixer.portsSplit[3])
                                                 annotation (Line(
              points={{8,18},{8,40.1667},{-15,40.1667}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(watersource_mh1.port,pipe3.portIn)  annotation (Line(
              points={{26,-31},{8,-31},{8,-2}},
              color={0,127,255},
              smooth=Smooth.None));
          connect(timeTable.y,watersource_mh1.m_flowIn) annotation (Line(
              points={{69.2,16},{54,16},{54,14},{38.6,14},{38.6,-25.6}},
              color={0,0,127},
              pattern=LinePattern.None,
              smooth=Smooth.None));

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
                    -100},{100,100}}), graphics),
            experiment(StopTime=12),
            Commands(file=\"Scripts/tests/splitterMixer_test.mos\"
                \"splitterMixer_test\"),
          Documentation(
             info=\"<HTML>
        <p>
           This is a test case for the SplitterMixer component <br>
           The model restrictions are:
                <ul>
                        <li> none
                </ul>
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
     </HTML>\",
             revisions=\"<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>\"));
        end splitterMixer_test;
      end Tests;
    end Junctions;

    package Pipes \"Cylindrical water/steam flow aggragates\"

      package Tests \"Tests for Pipes\"
            // within SiemensPower.Components.Pipes.Tests;

        model tube_ownMedia_test \"Test of tube\"
            extends Modelica.Icons.Example;
          SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                                   m_flow_start=
       " + "                                                    50, h_start=
                                                                  500e3)
            annotation (Placement(transformation(extent={{-100,20},{-80,40}},rotation=0)));
          SiemensPower.Boundaries.WaterSink watersink_ph(
                                               p_start=
                                                  30e5, h_start=
                                                           1000e3)
            annotation (Placement(transformation(extent={{80,20},{100,40}},rotation=0)));
          SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                             20)
            annotation (Placement(transformation(extent={{-32,74},{-12,94}}, rotation=0)));
          SiemensPower.Components.Pipes.TubeOwnMedia EVA(
            numberOfNodes=
              20,
            alphaOffset=5000,
            geoPipe(L=40, Nt=100),
            considerMassAccelaration=
                        false,
            considerDynamicPressure=
                         true,
            m_flow_start=
                    50,
            hIn_start= 1000e3,
            hOut_start= 1000e3,
            pIn_start= 3100000,
            pOut_start= 3000000,
            useINTH2O=
                   false)
                  annotation (Placement(transformation(extent={{0,20},{20,40}},
                  rotation=0)));
          SiemensPower.Blocks.TimeTable timeTable(table=[0,0; 1000,100e6; 2000,100e6])
            annotation (Placement(transformation(extent={{-80,74},{-60,94}}, rotation=0)));
          SiemensPower.Components.Pipes.TubeOwnMedia ECO(
            numberOfNodes=
              10,
            geoPipe(L=10, Nt=100),
            considerMassAccelaration=
                        false,
            considerDynamicPressure=
                         true,
            delayInnerHeatTransfer=
                        true,
            m_flow_start=
                    50,
            hIn_start= 500e3,
            hOut_start= 1000e3,
            pIn_start= 3100000,
            pOut_start= 3000000,
            useINTH2O=
                   false)
                  annotation (Placement(transformation(extent={{-60,40},{-38,20}},
                  rotation=0)));
          SiemensPower.Blocks.TimeTable timeTable1(table=[0,30e5; 1100,30e5; 1400,31e5; 2000,31e5])
            annotation (Placement(transformation(extent={{44,70},{64,90}}, rotation=0)));
          Modelica.Blocks.Sources.RealExpression realExpression(y=25e6)
            annotation (Placement(transformation(extent={{-102,-12},{-82,8}}, rotation=
                    0)));
          SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow1(numberOfCells=
                                                              10)
            annotation (Placement(transformation(extent={{-60,-20},{-40,0}}, rotation=0)));
          SiemensPower.Components.Pipes.TubeOwnMedia SH(
            numberOfNodes=
              10,
            geoPipe(L=10, Nt=100),
            considerMassAccelaration=
                        false,
            considerDynamicPressure=
                         true,
            initializeInletPressure=
                   false,
            m_flow_start=
                    50,
            hOut_start= 2000e3,
            delayInnerHeatTransfer=
                        true,
            pIn_start= 3200000,
            pOut_start= 3000000,
            hIn_start= 2000e3)
                  annotation (Placement(transformation(extent={{40,-20},{62,-40}},
                  rotation=0)));
          SiemensPower.Boundaries.WaterSink watersink_ph1(
                                                        h_start=
                                                           2000e3, p_start=
                                                                      3000000)
            annotation (Placement(transformation(extent={{80,-40},{100,-20}},  rotation=
                   0)));
          Modelica.Blocks.Sources.RealExpression realExpression1(y=0)
            annotation (Placement(transformation(extent={{-14,-68},{6,-48}}, rotation=0)));
          SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow2(numberOfCells=
                                                              10)
            annotation (Placement(transformation(extent={{16,-70},{36,-50}}, rotation=0)));
          SiemensPower.Boundaries.WaterSourceWithSetPressure watersource_ph(
                                                   h0=2000e3, p0=3200000)
            annotation (Placement(transformation(extent={{0,-40},{20,-20}},  rotation=0)));
          SiemensPower.Blocks.TimeTable timeTable2(table=[0,32e5; 200,32e5; 800,35e5; 2000,35e5])
            annotation (Placement(transformation(extent={{-20,-20},{0,0}},  rotation=0)));
        equation

          connect(prescribedHeatFlow.portsOut,
                                          EVA. gasSide)            annotation (Line(
                points={{-12,84},{10,84},{10,36.6}}, color={191,0,0}));

          connect(timeTable.y,prescribedHeatFlow. Q_flow)
            annotation (Line(points={{-59,84},{-32,84}}, color={0,0,127}));
          connect(watersource_mh.port,ECO.portIn)  annotation (Line(points={{-80,30},{
                  -60,30}},                                  color={0,127,255}));
          connect(ECO.portOut,EVA.portIn) annotation (Line(points={{-38,30},{-29.125,30},
                  {-29.125,29.9},{-24.25,29.9},{-24.25,30},{0,30}},
                          color={0,127,255}));
          connect(prescribedHeatFlow1.portsOut,
                                           ECO. gasSide) annotation (Line(points={{-40,-10},
                  {-49,-10},{-49,23.4}},    color={191,0,0}));
          connect(EVA.portOut,
                             watersink_ph. port) annotation (Line(points={{20,30},{20,
                  30},{80,30}},                    color={0,127,255}));
          connect(timeTable1.y,watersink_ph.p_set) annotation (Line(points={{65,80},{86,
                  80},{86,38}}, color={0,0,127}));
          connect(realExpression.y,prescribedHeatFlow1. Q_flow)
            annotation (Line(points={{-81,-2},{-76,-2},{-76,-10},{-60,-10}},
                                                         color={0,0,127}));
          connect(watersink_ph1.port,SH.portOut) annotation (Line(points={{80,-30},{72,
                  -30},{62,-30}},                            color={0,127,255}));
          connect(realExpression1.y,prescribedHeatFlow2. Q_flow)
            annotation (Line(points={{7,-58},{16,-58},{16,-60}},
                                                        color={0,0,127}));
          connect(prescribedHeatFlow2.portsOut,
                                           SH. gasSide) annotation (Line(points={{36,-60},
                  {52,-60},{52,-36.6},{51,-36.6}},      color={191,0,0}));
          connect(watersource_ph.port,SH.portIn)  annotation (Line(points={{20,-30},{30,
                  -30},{40,-30}},                            color={0,127,255}));
          connect(timeTable2.y,watersource_ph.pIn)   annotation (Line(points={{1,-10},{
                  6,-10},{6,-22}},
                               color={0,0,127}));
          annotation (Documentation(info=\"<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>\"),  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                    100,100}}),
                    graphics),
            experiment(
              StopTime=2000,
              NumberOfIntervals=2000,
              Tolerance=1e-005),
            Commands(file=\"Scripts/tests/tube_ownMedia_test.mos\"
                \"tube_ownMedia_test\"));
        end tube_ownMedia_test;
      annotation (Documentation(info=\"<html>
This package contains tests.
</html>\"));
      end Tests;

      model TubeOwnMedia
        \"SimpleMedia-Tube (incl wall) with detailed energy , integrated momentum and mass balance\"
        import SI = SiemensPower.Units;
        extends SiemensPower.Utilities.BaseClasses.PartialTwoPortTransport;
        constant Real g=Modelica.Constants.g_n;
        constant Real pi=Modelica.Constants.pi;
        //constant Medium.AbsolutePressure pcrit=Medium.fluidConstants[1].criticalPressure;
        //constant Medium.Temperature Tcrit=Medium.fluidConstants[1].criticalTemperature;

         parameter Boolean initializeInletPressure=true
          \"mp or pp boundary conditions\"                                               annotation(evaluate=true);
        parameter Integer numberOfNodes(min=2) = 2
          \"Number of nodes for thermal variables\"                                          annotation(Dialog(group=\"Geometry and pressure drop parameters\"));
        parameter SiemensPower.Ut" + "ilities.Structures.PipeGeo geoPipe
          \"Geometry of tube\"                                                           annotation(Dialog(group=\"Geometry and pressure drop parameters\"));
        parameter SI.MassFlowRate m_flowLaminar=0.001
          \"(small) mass flow rate at wich laminar equals turbulent pressure drop\"
                                                                                  annotation(Dialog(group=\"Geometry and pressure drop parameters\"));
        parameter Boolean considerDynamicMomentum=true
          \"der(m_dot) accounted for, be careful!\" annotation(evaluate=true);
        parameter Boolean considerMassAccelaration=true
          \"Inertial phenomena d/dz(m_dot^2/d) accounted for\" annotation(evaluate=true);
        parameter Boolean initializeSteadyStateEnthalpies=true
          \"lets initialize der(h)=0\"                                                      annotation(evaluate=true, Dialog(tab=\"Initialization\"));
        parameter Boolean initializeSteadyStateInletEnthalpy=true
          \"steady state initial condition for input enthalpy\" annotation(evaluate=true, Dialog(tab=\"Initialization\", enable=initializeSteadyStateEnthalpies));

        parameter Boolean useINTH2O=false
          \"water/steam table: true = useINTH2O, false = TTSE\";
        parameter Boolean considerDynamicPressure=false
          \"With der(p)/d in enthalpy balance\";
        parameter Boolean useDelayedPressure=false \"Pressure delay\";
        parameter SI.Time timeDelayOfPressure=0.1
          \"Artificial delay time for delay of pressure value\" annotation(Dialog(enable=useDelayedPressure));
        parameter Real hydP=0.6 \"Part of portIn for p\";
        parameter Real hydM=0.4 \"Part of portOut for m_flow\";

        parameter SI.CoefficientOfHeatTransfer alphaOffset=10e3
          \"alpha offset (in case of verysimple=true)\"                    annotation(Dialog(tab=\"Inner heat transfer\", enable=verysimple));
        parameter Real alphaFactor=0.0
          \"Factor for state dependent alpha term (in case of verysimple=true)\"                    annotation(Dialog(tab=\"Inner heat transfer\", enable=verysimple));

        parameter Boolean delayInnerHeatTransfer=false
          \"With delay of qMetalFluid\"                                              annotation(Dialog(tab=\"Inner heat transfer\"));
        parameter SI.Time timeDelayOfInnerHeatTransfer=1
          \"artificial delay time for qMetalFluid\"             annotation(Dialog(tab=\"Inner heat transfer\",enable=delayInnerHeatTransfer));

        // Init parameters
        parameter Boolean useHeatInput=true
          \"Initialisation of qMetalFluidDelayed=qMetalFluid\"                                   annotation(Dialog(tab=\"Initialization\", group=\"Heat transfer\"));
        parameter Boolean initializeWithZeroInnerHeatFlow=false
          \"Initialisation of qMetalFluidDelayed=0\"                                                       annotation(Dialog(tab=\"Initialization\",group=\"Heat transfer\",enable=(useHeatInput==false) and delayInnerHeatTransfer));

        // wall parameters
       parameter Integer numberOfWallLayers(min=1)=3 \"Number of wall layers\" annotation(Dialog(group=\"Wall\"),choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
       parameter String initOptWall=\"steadyState\" \"Initialisation option\" annotation (Dialog(tab=\"Initialization\",group=\"Wall\"),
        choices(
          choice=\"noInit\" \"No initial equations\",
          choice=\"steadyState\" \"Steady-state initialization\",
          choice=\"fixedTemperature\" \"Fixed-temperatures initialization\"));
        parameter SI.Temperature T_wall_start[numberOfNodes]=T_start
          \"start values for wall temperatures\"
                                             annotation (Dialog(tab=\"Initialization\",group=\"Wall\"));
       parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
          \"Wall metal properties\"                                                      annotation (Dialog(group=\"Wall\"));

        final parameter SI.Length di = geoPipe.d_out - 2*geoPipe.s;
        final parameter SI.Area A =  0.25*pi*di^2;
        final parameter SI.Length dz= geoPipe.L/numberOfNodes;
        final parameter SI.Volume V = A*geoPipe.L;
        final parameter SI.Volume V_total = geoPipe.Nt*V;

        SI.Temperature T[numberOfNodes](start=T_start);
        SI.Density d[numberOfNodes](start=rho0);
        SI.Density dAverage(start=sum(rho0)/numberOfNodes);
        SI.SpecificVolume vol[numberOfNodes];
        SI.SpecificVolume volAverage(start=1/SiemensPower.Media.TTSE.Utilities.rho_ph(0.5*(pIn_start+pOut_start),0.5*(hIn_start+hOut_start)));
        SI.SpecificEnthalpy h[numberOfNodes](start=SiemensPower.Utilities.Functions.my_linspace(hIn_start, hOut_start, numberOfNodes));
        SI.AbsolutePressure dpfric(start=0.015*geoPipe.L/(geoPipe.d_out-2*geoPipe.s)^5*m_flow_start/geoPipe.Nt*0.5*(1/rho0[1] + 1/rho0[numberOfNodes]));
        SI.AbsolutePressure dphyd(start=g*geoPipe.H*sum(rho0)/numberOfNodes);
        SI.HeatFlux qMetalFluidDelayed[numberOfNodes];
        SI.Length perimeter;
        SI.MassFlowRate m_flow(start=m_flow_start/geoPipe.Nt);
        SI.AbsolutePressure p(start=0.5*(pIn_start+pOut_start)) \"pressure\";
        SI.AbsolutePressure pUndelayed(start=0.5*(pIn_start+pOut_start));
        Real zeta \"friction coefficient\";
        SI.CoefficientOfHeatTransfer alpha;

         Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a gasSide[numberOfNodes](T(start=T_wall_start))
          \"Outer wall heat port\"
        annotation (extent=[-14,54; 14,78]);

        SiemensPower.Components.SolidComponents.Wall wall(
          numberOfNodes=numberOfNodes,
          numberOfWallLayers=numberOfWallLayers,
          metal=metal,
          length =   geoPipe.L,
          wallThickness=geoPipe.s,
          T_start =   T_wall_start,
          initOpt=initOptWall,
          numberOfParallelTubes=geoPipe.Nt,
          diameterInner =   geoPipe.d_out - 2*geoPipe.s)
          \"Metal wall of the tube\"
                       annotation (extent=[-10,34; 10,54]);

        SiemensPower.Interfaces.portHeat heatport(
                                     numberOfNodes=numberOfNodes)
          \"Inner wall (masked) heat port \"                                             annotation (extent=[-10,-8; 10,12]);

      protected
        final parameter SI.Temperature T_start[numberOfNodes]=SiemensPower.Media.TTSE.Utilities.T_ph(SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes),SiemensPower.Utilities.Functions.my_linspace(hIn_start,hOut_start,numberOfNodes))
          \"start values for fluid temperatures\";
        final parameter SI.Density rho0[numberOfNodes]=SiemensPower.Utilities.Functions.my_linspace(SiemensPower.Media.TTSE.Utilities.rho_ph(pIn_start,hIn_start), SiemensPower.Media.TTSE.Utilities.rho_ph(pOut_start,hOut_start), numberOfNodes);

        SI.HeatFlux qMetalFluid[numberOfNodes];
        Real drdp[numberOfNodes];
        Real drdh[numberOfNodes];
        inner SI.Temperature TWall[numberOfNodes];
        Integer TTSEid(start=0);

      algorithm
      //    when (initial()) then
      //      if not useINTH2O then
      //       TTSEid:=SiemensPower.Media.TTSE.init_ttse();
      //      else
             TTSEid:=0;
      //      end if;
      //    end when;

      initial equation

         // h
        if (initializeSteadyStateInletEnthalpy and initializeSteadyStateEnthalpies) then
              der(h[1])=0;
        end if;
        if initializeSteadyStateEnthalpies then
            for j in 2:numberOfNodes loop
               der(h[j]) = 0;
           end for;
        end if;

        // m_flow
        if (considerDynamicMomentum) then
              der(m_flow) = 0;
        end if;

         // p (or d)
        if (initializeInletPressure) then
            der(p) = 0;
        end if;

        // qMetalFluidDelayed
        if (useHeatInput and delayInnerHeatTransfer) then
                qMetalFluidDelayed=qMetalFluid;
        elseif (initializeWithZeroInnerHeatFlow) then
              qMetalFluidDelayed=zeros(numberOfNodes);
        end if;

      equation

        perimeter=pi*di;
        dAverage=sum(d)/numberOfNodes;
        volAverage=sum(vol)/numberOfNodes;
        for j in 1:numberOfNodes loop
            vol[j]=1.0/d[j];
        end for;

        portIn.h_outflow = h[1];
        portOut.h_outflow = h[numberOfNodes];

        // pressure and mass flow rate
        pUndelayed = hydP*portIn.p + (1-hydP)*portOut.p;
        if useDelayedPressure then
              der(p) = (pUndelayed-p)/timeDelayOfPressure;
        else
              p = pUndelayed;
        end if;
        m_flow = (hydM*portIn.m_flow - (1-hydM)*portOut.m_flow)/geoPipe.Nt;

        // friction pressure loss
       zeta=((1.14-2*Modelica.Math.log10(geoPipe.r/di))^(-2)+geoPipe.zeta_add*di/geoPipe.L);
       dpfric = zeta*m_flow*(abs(m_flow)+m_flowLaminar)*volAverage*geoPipe.L/(2*A^2*di);

        // hydrostatic pressure drop;
        dphyd=g*geoPipe.H*dAverage;

          // mass balance
       // der(dAverage) + (-portOut.m_flow-portIn.m_flow)/(geoPipe.Nt*V) = 0;
          (1/numberOfNodes)*(sum(drdp)*der(p) + drdh*der(h))  + (-portOut.m_flow-portIn.m_flow)/(geoPipe.Nt*V) = 0;

        // momentum balance
        if (considerDynamicMomentum) then
          if (considerMassAccelaration) then
            der(m_flow) + dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L+ m_flow^2*(1/d[numberOfNodes]-1/d[1])/V = 0;
          else
            der(m_flow) + dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L = 0;
          end if;
        else
          if (considerMassAccelaration) then
            dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L+ m_flow^2*(1/d[numberOfNodes]-1/d[1])/V = 0;
          else
            dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L = 0;
         " + " end if;
        end if;
       // energy balance
         if (m_flow<0) then
          if (considerDynamicPressure) then
            der(h[1]) + m_flow*(h[2]-h[1])/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di) + der(p)/d[1];
          else
            der(h[1]) + m_flow*(h[2]-h[1])/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di);
          end if;
        else
          if (considerDynamicPressure) then
            der(h[1]) + m_flow*(h[1]-inStream(portIn.h_outflow))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di) + der(p)/d[1];
          else
            der(h[1]) + m_flow*(h[1]-inStream(portIn.h_outflow))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di);
          end if;
        end if;

      for j in 2:(numberOfNodes-1) loop
          if (m_flow<0) then
          if (considerDynamicPressure) then
            der(h[j]) + m_flow*(h[j+1]-h[j])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di) + der(p)/d[j];
          else
            der(h[j]) + m_flow*(h[j+1]-h[j])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di);
          end if;
        else
          if (considerDynamicPressure) then
            der(h[j]) + m_flow*(h[j]-h[j-1])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di) + der(p)/d[j];
          else
            der(h[j]) + m_flow*(h[j]-h[j-1])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di);
          end if;
        end if;
      end for;

        if (m_flow<0) then
          if (considerDynamicPressure) then
            der(h[numberOfNodes]) + m_flow*(inStream(portOut.h_outflow)-h[numberOfNodes])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di) + der(p)/d[numberOfNodes];
          else
            der(h[numberOfNodes]) + m_flow*(inStream(portOut.h_outflow)-h[numberOfNodes])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di);
          end if;
        else
          if (considerDynamicPressure) then
            der(h[numberOfNodes]) + m_flow*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di) + der(p)/d[numberOfNodes];
          else
            der(h[numberOfNodes]) + m_flow*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di);
          end if;
        end if;

       // water/steam properties
       //p = sum(SiemensPower.Media.IntH2O.p_rhoh(dAverage,h[3]);
       for j in 1:numberOfNodes loop
          if useINTH2O then
             T[j] =  SiemensPower.Media.IntH2O.T_rhoh(d[j],h[j]);
            (d[j],drdp[j],drdh[j]) =  SiemensPower.Media.IntH2O.rho_ph_dpdh(p, h[j]);
          else  // TTSE
              T[j]    = SiemensPower.Media.TTSE.Utilities.T_ph(p, h[j]);
              d[j]  = SiemensPower.Media.TTSE.Utilities.rho_ph(p, h[j]);
              drdp[j] = SiemensPower.Media.TTSE.Utilities.rho_ph_dp(p, h[j]);
              drdh[j] = SiemensPower.Media.TTSE.Utilities.rho_ph_dh(p, h[j]);

          end if;
       end for;

        // Inner heat transfer
        alpha = alphaOffset + 400*Modelica.Fluid.Utilities.regRoot(abs(m_flow)/A)*alphaFactor;
        qMetalFluid = alpha * (TWall-T);
        heatport.Q_flow = perimeter*geoPipe.Nt*dz*qMetalFluidDelayed;
        if (delayInnerHeatTransfer) then
              der(qMetalFluidDelayed) = (qMetalFluid-qMetalFluidDelayed)/timeDelayOfInnerHeatTransfer;
        else
              qMetalFluidDelayed=qMetalFluid;
        end if;

        connect(gasSide, wall.port_ext) annotation (points=[1.77636e-015,66;
              1.77636e-016,66; 1.77636e-016,48.9], style(color=42, rgbcolor={191,0,0}));
        connect(wall.port_int, heatport.port) annotation (points=[-0.1,39.4; -0.1,
              32.7; 0,32.7; 0,5.4], style(color=42, rgbcolor={191,0,0}));

      annotation (Documentation(info=\"<HTML>
<p>This tube model comes with a detailed energy balance, but <b>integrated</b> momentum and mass balance.
See <a href=\\\"../Documents/tube_integration.pdf\\\"> pdf documentation </a>for details.<br>
The tube is heated. The water/steam media is simplified: You can chose between:
<ul>
<li> inth20
<li> Ideal steam
</ul>
<p>

       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>

</HTML>\",   revisions=\"<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>\"),       Icon(graphics={
              Rectangle(
                extent={{-80,54},{80,-60}},
                fillColor={0,255,255},
                fillPattern=FillPattern.Solid,
                pattern=LinePattern.None,
                lineColor={0,0,0}),
              Text(
                extent={{-76,30},{78,-26}},
                lineColor={0,0,0},
                fillColor={0,128,255},
                fillPattern=FillPattern.Solid,
                textString=\"%name\"),
              Rectangle(
                extent={{-80,54},{80,40}},
                pattern=LinePattern.None,
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                lineColor={0,0,0}),
              Rectangle(
                extent={{-80,-46},{80,-60}},
                pattern=LinePattern.None,
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                lineColor={0,0,0})}));
      end TubeOwnMedia;

      model TubeWithoutWall
        \"Tube with detailed energy, integrated momentum and mass balance\"
        import SI = SiemensPower.Units;
        extends SiemensPower.Utilities.BaseClasses.BaseTube;

        replaceable model Friction =
            SiemensPower.Utilities.PressureLoss.RoughnessFlow constrainedby
          SiemensPower.Utilities.PressureLoss.PartialFrictionSinglePhase
          \"Friction pressure loss correlation\"   annotation (Dialog(group=\"Geometry and correlations\"),choicesAllMatching=true);
        parameter String locationMassflow=\"interpolation\"
          \"location of mass flow rate\"
            annotation(choices(choice=\"inlet\" \"inlet\",
                               choice=\"outlet\" \"outlet\",
                               choice=\"interpolation\" \"interpolation\"),evaluate=true);
        parameter Boolean useDelayedPressure=false \"Pressure delay\" annotation(Dialog(tab=\"Advanced\"),evaluate=true);
        parameter SI.Time timeDelayOfPressure=0.1
          \"Artificial delay time for delay of pressure value\" annotation(Dialog(tab=\"Advanced\"),enable=useDelayedPressure);

        Medium.AbsolutePressure p(start=hydP*pIn_start + (1-hydP)*pOut_start)
          \"pressure\";

      protected
        final parameter Real hydM=(if (locationMassflow==\"inlet\") then 1.0 else if (locationMassflow==\"outlet\") then 0.0 else  0.4)
          \"Part of portIn for p\";
        final parameter Real hydP=1-hydM \"Part of portIn for m_flow\";
        Medium.AbsolutePressure pUndelayed(start=hydP*pIn_start + (1-hydP)*pOut_start);
        Friction friction(geoPipe=geoPipe, dz=geoPipe.L, m_flow=m_flows[1], p=p, rho=d_av, h=fluid[1].h, eta=eta[1], steamQuality = 1.5, xdo=0.9);

      initial equation
        // m_flow
        if (considerDynamicMomentum and useDynamicMassBalance) then
              der(m_flows[1]) = 0;
        end if;

        // d oder p
       if (useDynamicMassBalance and initializeInletPressure) then
         //der(d_av)=0;
          der(p) = 0;
       end if;

      equation
        // lumped pressure and mass flow rate
        if (locationMassflow==\"inlet\") then
          pUndelayed = portOut.p;
          m_flowsZero = portIn.m_flow/geoPipe.Nt;
        elseif (locationMassflow==\"outlet\") then
          pUndelayed = portIn.p;
          m_flowsZero = -portOut.m_flow/geoPipe.Nt;
        else
          pUndelayed = hydP*portIn.p + (1-hydP)*portOut.p;
          m_flowsZero = (hydM*portIn.m_flow - (1-hydM)*portOut.m_flow)/geoPipe.Nt;
        end if;
        if useDelayedPressure then
           der(p) = (pUndelayed-p)/timeDelayOfPressure;
        else
           p = pUndelayed;
        end if;
        m_flows = m_flowsZero*ones(numberOfNodes);

        //  pressure loss
        dpfric=friction.dp;
        dphyd=g*geoPipe.H*d_av;

        // mass balance
        if (useDynamicMassBalance) then
            VTotal*der(d_av) =  portIn.m_flow + portOut.m_flow;
        else
            portIn.m_flow + portOut.m_flow = 0;
        end if;

        // momentum balance
        if considerDynamicMomentum then
            geoPipe.L/A*der(m_flows[1]) = portIn.p-portOut.p -(dpfric+dphyd);
        else
            portIn.p-portOut.p  = dpfric+dphyd;
        end if;

       // water/steam properties
        fluid.p = p*ones(numberOfNodes);

        annotation (Documentation(info=\"<HTML>
<p>This tube model comes with a detailed energy, but integrated momentum and mass balance.
See <a href=\\\"../Documents/tube_integration.pdf\\\"> pdf documentation </a>for details of the integration of the hydrodynamic equations.
Both heat transfer and friction pressure drop can be selected from a set of correlations.
 </p>
<h3>Model" + " restrictions</h3>
<ul>
<li>Mass accelaration pressure drop is not considered</li>
<li>The tube comes without wall. It is not possibel to connect external heating</li>
<li>dynamic mass balance has no effect if medium is incompressible </li>
</ul>
</p>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>

</HTML>\",   revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>\"));
      end TubeWithoutWall;
    annotation (Documentation(info=\"<html>
There are two families of tubes, which both comes with a unheated (WithoutWall) and a heated tube:
<ul>
<li> Tube (with distributed enthalpy, lumped pressure and massflow)
<li> TubeDistributed (with distributed enthalpy, pressure and massflow)
</ul>
<p>
<img src=\\\"..\\\\Documents\\\\Images\\\\ClassDiagramTubes.png\\\"></img>
</html>\"));
    end Pipes;

    package SolidComponents \"walls, shafts and similar\"
      package Tests
            // within SiemensPower.Components.SolidComponents.Tests;

        model wall_test \"Test of wall\"
        // extends Modelica.Icons.Example;

          SiemensPower.Components.SolidComponents.Wall wall(
                    initOpt=\"fixedTemperature\",
            considerAxialHeatTransfer=
                                  false,
            numberOfNodes=
              5,
            T_start=
               {500,510,520,590,600})
                    annotation (Placement(transformation(extent={{-14,-10},{6,10}},
                  rotation=0)));
          SiemensPower.Boundaries.Reservoir reservoir(
                                              reservoir=\"temperature\", N=5)
            annotation (Placement(transformation(extent={{-20,-18},{12,-40}}, rotation=
                    0)));
          SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                             5)
            annotation (Placement(transformation(extent={{-46,20},{-26,40}}, rotation=0)));
          SiemensPower.Blocks.TimeTable heatInput(table=[0,0; 5,0; 10,100e3; 15,100e3])
            annotation (Placement(transformation(extent={{-88,20},{-68,40}}, rotation=0)));
        equation

          connect(wall.port_int,reservoir.ports)   annotation (Line(points={{-4.1,-4.6},
                  {-4.1,-11.3},{-4,-11.3},{-4,-21.19}}, color={191,0,0}));

          connect(prescribedHeatFlow.portsOut,
                                           wall.port_ext) annotation (Line(points={{-26,
                  30},{-4,30},{-4,4.9}}, color={191,0,0}));
          connect(heatInput.y, prescribedHeatFlow.Q_flow)
            annotation (
        Documentation(info=\"<HTML>
<p>This is a simple test of the wall aggregate.
<p>
</HTML>\",     revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>\"),  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                    100,100}}), graphics),
            experiment(StopTime=25),
            Line(points={{-67,30},{-46,30}}, color={0,0,127}));

          annotation (Commands(file=\"Scripts/tests/wall_test.mos\" \"wall_test\"),
              Documentation(info=\"<HTML>
<p>This is a simple test of the wall aggregate.
<p>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                        <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
        end wall_test;
      end Tests;

      model Wall
        \"Cylindrical metal tube with variable number of wall layers Nwall\"
        import SI = SiemensPower.Units;

        parameter Integer numberOfNodes(min=1)=2 \"Number of nodes\";
        parameter Integer numberOfWallLayers(min=1)=3 \"Number of wall layers\"annotation(choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));

        parameter Boolean assumePlainHeatTransfer=false
          \"no logarithmic correction\" annotation (Dialog(enable=considerConductivity));
      /*   parameter Boolean userdefinedmaterial=true
    \"define own fixed material properties\" annotation (Dialog(group=\"Material\"));
  replaceable ThermoPower.Thermal.MaterialProperties.Metals.CarbonSteel_A106C[numberOfNodes] Material(
              each npol=3)
   extends ThermoPower.Thermal.MaterialProperties.Interfaces.PartialMaterial
    \"pre-defined material properties\"       annotation (choicesAllMatching = true, Dialog(enable=userdefinedmaterial==false, group=\"Material\")); */
         parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
          \"Wall metal properties\"                                                      annotation (Dialog(enable=userdefinedmaterial, group=\"Material\"));
        parameter Integer numberOfParallelTubes(min=1)=1
          \"Number of parallel tubes\";
        parameter SI.Length length=1 \"Tube length\";
        parameter SI.Length diameterInner=0.08
          \"Internal diameter (single tube)\";
        parameter SI.Length wallThickness=0.008 \"Wall thickness\";
        parameter Boolean useDynamicEquations=true
          \"switch off for steady-state simulations\" annotation (evaluate=true);

        parameter Boolean considerConductivity=true
          \"Wall conduction resistance accounted for\";
        parameter Boolean considerAxialHeatTransfer=false
          \"With (small!) heat transfer in the wall parallel to the flow direction\"
                annotation (Dialog(enable=considerConductivity));
       parameter String initOpt=\"steadyState\" \"Initialisation option\" annotation (Dialog(group=\"Initialization\"),
        choices(
          choice=\"noInit\" \"No initial equations\",
          choice=\"steadyState\" \"Steady-state initialization\",
          choice=\"fixedTemperature\" \"Fixed-temperatures initialization\"));
        parameter SI.Temperature T_start[numberOfNodes] = fill(300,numberOfNodes)
          \"Temperature start values for inner layer\";

       // final parameter SI.HeatCapacity C_total = metal.cp*metal.rho*lengthTube*numberOfParallelTubes*Modelica.Constants.pi*wallThickness*(diameterInner+wallThickness);

        SiemensPower.Components.SolidComponents.Walllayer layer[
                                                numberOfWallLayers](
          each numberOfNodes = numberOfNodes,
          diameterInner =       if (numberOfWallLayers == 1) then diameterInner*ones(1) else
             SiemensPower.Utilities.Functions.my_linspace(
              diameterInner,
              diameterInner + 2*wallThickness - 2*wallThickness/numberOfWallLayers,
              numberOfWallLayers),
          each numberOfParallelTubes =    numberOfParallelTubes,
          each length =    length,
          each wallThickness =   wallThickness/numberOfWallLayers,
          each T_start = T_start,
          each metal = metal,
          each considerConductivity =   considerConductivity,
          each considerAxialHeatTransfer = considerAxialHeatTransfer,
          each assumePlainHeatTransfer =   assumePlainHeatTransfer,
          each initOpt =   initOpt,
          each useDynamicEquations = useDynamicEquations);

        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes] port_ext
          \"Outer heat port\"
          annotation (Placement(transformation(extent={{-14,36},{14,62}}, rotation=0)));
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes] port_int
          \"Inner heat port\"
          annotation (Placement(transformation(extent={{-14,-58},{12,-34}}, rotation=
                  0)));

      equation
        connect(layer[1].port_int, port_int);
        for j in 2:numberOfWallLayers loop
           connect(layer[j-1].port_ext,layer[j].port_int);
        end for;
        connect(layer[numberOfWallLayers].port_ext, port_ext);

        annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}),
                            graphics),
                             Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}), graph" + "ics={
              Rectangle(
                extent={{-92,36},{90,-34}},
                lineColor={0,0,0},
                pattern=LinePattern.None,
                fillPattern=FillPattern.VerticalCylinder,
                fillColor={215,215,215}),
              Text(
                extent={{-86,32},{80,-26}},
                lineColor={0,0,0},
                pattern=LinePattern.None,
                fillColor={175,175,175},
                fillPattern=FillPattern.Solid,
                textString=\"%name\"),
              Text(
                extent={{-44,-38},{-16,-50}},
                lineColor={0,0,0},
                fillColor={175,175,175},
                fillPattern=FillPattern.Solid,
                textString=\"int\"),
              Text(
                extent={{-46,54},{-16,40}},
                lineColor={0,0,0},
                fillColor={175,175,175},
                fillPattern=FillPattern.Solid,
                textString=\"ext\")}),
          Documentation(info=\"<html>
This model is based on the Walllayer model which represents a cylindrical metal tube wall with a single layer.
The parameter numberOfWallLayers says how many layers will be accounted for in that wall. The counting of layers begins at the inner side, i.e. layer[numberOfNodes] is the outside layer.
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                          <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",       revisions=\"<html>
<ul>
<li> December 2006  by Haiko Steuer
</ul>
</html>\"));
      end Wall;

      model Walllayer \"Cylindrical metal tube (single layer)\"
        import SI = SiemensPower.Units;

        constant Real pi=Modelica.Constants.pi;
        parameter Integer numberOfNodes(min=1)=2 \"Number of nodes\";
        parameter Boolean assumePlainHeatTransfer=false
          \"no logarithmic correction\" annotation (Dialog(enable=considerConductivity));
        parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
          \"Wall metal properties\"                                                      annotation (Dialog(enable=userdefinedmaterial, group=\"Material\"));
        parameter Integer numberOfParallelTubes(min=1)=1
          \"Number of parallel tubes\";
        parameter SI.Length length=1 \"Tube length\";
        parameter SI.Length diameterInner=0.08
          \"Internal diameter (single tube)\";
        parameter SI.Length wallThickness=0.008 \"Wall thickness\";
        parameter Boolean useDynamicEquations=true
          \"switch off for steady-state simulations\" annotation (evaluate=true);

        parameter Boolean considerConductivity=true
          \"Wall conduction resistance accounted for\"                                           annotation (Evaluate=true);
        parameter Boolean considerAxialHeatTransfer=false
          \"With heat transfer in the wall parallel to the flow direction\"
                annotation (Evaluate=true, Dialog(enable=considerConductivity));
        parameter String initOpt=\"steadyState\" \"Initialisation option\" annotation (Dialog(group=\"Initialization\"),
        choices(
          choice=\"noInit\" \"No initial equations\",
          choice=\"steadyState\" \"Steady-state initialization\",
          choice=\"fixedTemperature\" \"Fixed-temperatures initialization\"));

        parameter SI.Temperature T_start[numberOfNodes]
          \"Temperature start values\"                                                     annotation (Dialog(group=\"Initialization\"));

        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes] port_ext(T(start = T_start))
          \"Outer heat port\"
          annotation (Placement(transformation(extent={{-16,20},{16,48}}, rotation=0)));                                                          //(T(start = SiemensPower.Utilities.Functions.my_linspace(Tstart1,TstartN,numberOfNodes)))
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes] port_int(T(start = T_start))
          \"Inner heat port\"
          annotation (Placement(transformation(extent={{-14,-48},{16,-20}}, rotation=
                  0)));

        SI.Area Am \"Area of the metal tube cross-section\";
        SI.Temperature T[numberOfNodes](start=T_start) \"Node temperatures\";
        SI.Length rint;
        SI.Length rext;
        SI.Mass Tube_mass;
        SI.HeatCapacity HeatCap \"HeatCapacity of a Tube part\";

        SI.HeatFlowRate Q_flow_ax[numberOfNodes]
          \"axial(parallel) heat transfer\";

      initial equation
        if initOpt == \"noInit\" then
       // nothing to do
        elseif initOpt == \"steadyState\" then
          der(T) = zeros(numberOfNodes);
        elseif initOpt == \"fixedTemperature\" then // fixed temperatures at start
          T = T_start;
        else
          assert(false, \"Unsupported initialisation option\");
        end if;

      equation
        rint=diameterInner*0.5;
        rext=diameterInner*0.5+wallThickness;

       Tube_mass=(metal.rho*Am*length/numberOfNodes)* numberOfParallelTubes;
       HeatCap=metal.cp*Tube_mass;

        //  Energy balance
        for i in 1:numberOfNodes loop
          if (useDynamicEquations and wallThickness>0) then
              if (considerAxialHeatTransfer) then
                 HeatCap*der(T[i]) = port_int[i].Q_flow + port_ext[i].Q_flow +  Q_flow_ax[i];
              else
                 HeatCap*der(T[i]) = port_int[i].Q_flow + port_ext[i].Q_flow;
              end if;
          else
              if
                (considerAxialHeatTransfer) then
                 0.0 = port_int[i].Q_flow + port_ext[i].Q_flow +  Q_flow_ax[i];
              else
                 0.0 = port_int[i].Q_flow + port_ext[i].Q_flow;
              end if;
          end if;
        end for;

        Am = (rext^2-rint^2)*pi
          \"Area of the metal cross section of single tube\";
          if (considerConductivity and wallThickness>0) then
             for i in 1:numberOfNodes loop
                  if assumePlainHeatTransfer then
                        port_int[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_int[i].T-T[i])*2/(rext/rint-1);
                        port_ext[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_ext[i].T -T[i])*2/(1-rint/rext);
                  else
                        port_int[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_int[i].T-T[i])/(Modelica.Math.log((rext+rint)/(2*rint)));
                        port_ext[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_ext[i].T -T[i])/(Modelica.Math.log((2*rext)/(rint + rext)));
                  end if;
             end for;
             if (considerAxialHeatTransfer) then
                  Q_flow_ax[1] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[2]-T[1]);
                  for i in 2:(numberOfNodes-1) loop
                    Q_flow_ax[i] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[i-1]-2*T[i]+T[i+1]);
                  end for;
                  Q_flow_ax[numberOfNodes] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[numberOfNodes-1]-T[numberOfNodes]);
             else
                  Q_flow_ax = zeros(numberOfNodes);
             end if;
          else
            // No temperature gradients across the thickness
            port_int.T = T;
            port_ext.T = T;
            Q_flow_ax = zeros(numberOfNodes);
          end if;

        annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}), graphics={
              Rectangle(
                extent={{-80,20},{80,-20}},
                lineColor={0,0,0},
                fillColor={128,128,128},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-84,-22},{-32,-50}},
                lineColor={0,0,0},
                fillColor={128,128,128},
                fillPattern=FillPattern.Forward,
                textString=\"Int\"),
              Text(
                extent={{-82,50},{-34,24}},
                lineColor={0,0,0},
                fillColor={128,128,128},
                fillPattern=FillPattern.Forward,
                textString=\"Ext\"),
              Text(
                extent={{-100,-60},{100,-88}},
                lineColor={191,95,0},
                textString=\"%name\")}),
                                 Documentation(info=\"<HTML>
<p>This is the model of a cylindrical tube layer of solid material.
<p>The heat capacity (which is lumped at the center of the tube thickness) is accounted for, as well as the thermal resistance due to the finite heat conduction coefficient. Longitudinal heat conduction is neglected.
<p><b>Modelling options</b></p>
<p>The following options are available to specify the valve flow coefficient in fully open conditions:
<ul>
<li><tt>considerConductivity = false</tt>: the thermal resistance of the tube wall is neglected.
<li><tt>considerConductivity = true</t" + "t>: the thermal resistance of the tube wall is accounted for.
</ul>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                           <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>

                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> December 2006, adapted to SiemensPower by Haiko Steuer
<li><i>30 May 2005</i>
    by <a href=\\\"mailto:francesco.casella@polimi.it\\\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\\\"mailto:francesco.casella@polimi.it\\\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
\"));
      end Walllayer;
    end SolidComponents;
  annotation (Documentation(info=\"<html>
This package contains components of power plants.
</html>\"));
  end Components;

  package Interfaces \"Connectors\"
    connector portGasIn \"Gas connector with filled icon\"
      extends Modelica.Fluid.Interfaces.FluidPort;
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,191,0},
              fillColor={0,191,0},
              fillPattern=FillPattern.Solid), Text(extent={{-88,192},{112,98}},
                textString=\"%name\")}),
          Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
                100}}), graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,191,0},
              fillColor={0,191,0},
              fillPattern=FillPattern.Solid)}),
                                Documentation(
    info=\"<html>This connector differs from the Modelica.Fluid standard connector only in the annotation</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>

                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added to SiemensPower by Haiko Steuer
<li>original from SiemensLib</li>
</ul>
</html>\"));
    end portGasIn;

    connector portGasOut \"Gas connector with outlined icon\"
      extends Modelica.Fluid.Interfaces.FluidPort;
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,191,0},
              fillColor={0,191,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-80,80},{80,-80}},
              lineColor={0,191,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-88,192},{112,98}}, textString=\"%name\")}),
                                                             Icon(coordinateSystem(
              preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
              Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,191,0},
              fillColor={0,191,0},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{-80,80},{80,-80}},
              lineColor={0,191,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}),
                                Documentation(
    info=\"<html>This connector differs from the Modelica.Fluid standard connector only in the annotation</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>

                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> December 2006, added to SiemensPower by Haiko Steuer
<li>original from SiemensLib</li>
</ul>
</html>\"));

    end portGasOut;

    model portHeat \"Closing any heat port\"
      import SI = SiemensPower.Units;

      parameter Integer numberOfNodes=2 \"Number of nodes\";
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port[numberOfNodes]
        \"heat port\"
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
                                        Documentation(info=\"<html>
<p>This short model can be used to complete a heat-port connector vector!
It is used in any tube with wall.
</p>
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
<ul>
<li> January 2007, by Haiko Steuer
</ul>
</html>\"));
    end portHeat;

    connector FluidPort_a \"Generic fluid connector at design inlet\"
      extends SiemensPower.Interfaces.FluidPort;
      annotation (defaultComponentName=\"port_a\",
                  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Text(extent={{-150,110},{150,50}},
                textString=\"%name\")}),
           Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                100,100}}), graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,127,255},
              fillColor={0,127,255},
       " + "       fillPattern=FillPattern.Solid), Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_a;

    connector FluidPort
      \"Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)\"
      import SI = SiemensPower.Units;

     // replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
     //   \"Medium model\" annotation (choicesAllMatching=true);

      flow SI.MassFlowRate m_flow
        \"Mass flow rate from the connection point into the component\";
      SI.AbsolutePressure p \"Thermodynamic pressure in the connection point\";
      stream SI.SpecificEnthalpy h_outflow
        \"Specific thermodynamic enthalpy close to the connection point if m_flow < 0\";
      //stream SI.MassFraction Xi_outflow[Medium.nXi]
      //  \"Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0\";
      //stream SI.ExtraProperty C_outflow[Medium.nC]
      //  \"Properties c_i/m close to the connection point if m_flow < 0\";
    end FluidPort;

    connector FluidPorts_b
      \"Fluid connector with outlined, large icon to be used for vectors of FluidPorts (vector dimensions must be added after dragging)\"
      extends SiemensPower.Interfaces.FluidPort;

      annotation (defaultComponentName=\"ports_b\",
                  Diagram(coordinateSystem(
            preserveAspectRatio=false,
            extent={{-50,-200},{50,200}},
            grid={1,1},
            initialScale=0.2), graphics={
            Text(extent={{-75,130},{75,100}}, textString=\"%name\"),
            Rectangle(
              extent={{-25,100},{25,-100}},
              lineColor={0,0,0}),
            Ellipse(
              extent={{-25,90},{25,40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-25,25},{25,-25}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-25,-40},{25,-90}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-15,-50},{15,-80}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-15,15},{15,-15}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-15,50},{15,80}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}),
           Icon(coordinateSystem(
            preserveAspectRatio=false,
            extent={{-50,-200},{50,200}},
            grid={1,1},
            initialScale=0.2), graphics={
            Rectangle(
              extent={{-50,200},{50,-200}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-50,180},{50,80}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-50,50},{50,-50}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-50,-80},{50,-180}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-30,30},{30,-30}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-30,100},{30,160}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-30,-100},{30,-160}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPorts_b;

    connector FluidPort_b \"Generic fluid connector at design outlet\"
      extends SiemensPower.Interfaces.FluidPort;

      annotation (defaultComponentName=\"port_b\",
                  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-30,30},{30,-30}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-150,110},{150,50}}, textString=\"%name\")}),
           Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                100,100}}), graphics={
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,127,255},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-80,80},{80,-80}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_b;
  annotation (Documentation(info=\"<html>
This package contains interfaces if not present in the boundary package.
</html>\"));
  end Interfaces;

  package Media \"Media models\"
    package Common
      package MixtureGasNasa

      import Modelica.Media.IdealGases.*;

        extends Modelica.Media.IdealGases.Common.MixtureGasNasa( mediumName=\"MoistAir\",
           data={Common.SingleGasesData.H2O, Common.SingleGasesData.Air},
          fluidConstants={Common.FluidData.H2O,
            Common.FluidData.N2},
           substanceNames = {\"Water\",\"Air\"},
           reference_X={0.0,1.0});

        redeclare replaceable function thermalConductivity
          \"Return thermal conductivity for low pressure gas mixtures\"
          extends Modelica.Icons.Function;
          input ThermodynamicState state \"thermodynamic state record\";
          output ThermalConductivity lambda \"Thermal conductivity\";
        input Integer method=2
            \"method to compute single component thermal conductivity\";
        protected
        ThermalConductivity[nX] lambdaX \"component thermal conductivities\";
        DynamicViscosity[nX] eta \"component thermal dynamic viscosities\";
        SpecificHeatCapacity[nX] cp \"component heat capacity\";
        algorithm
        for i in 1:nX loop
            assert(fluidConstants[i].hasCriticalData, \"Critical data for \" +
              fluidConstants[i].chemicalFormula +
         \" not known. Can not compute thermal conductivity.\");
            eta[i] := Common.SingleGasNasa.dynamicViscosityLowPressure(
                state.T, fluidConstants[i].criticalTemperature,
                         fluidConstants[i].molarMass,
                         fluidConstants[i].criticalMolarVolume,
                         fluidConstants[i].acentricFactor,
                         fluidConstants[i].dipoleMoment);
            cp[i] := Common.SingleGasNasa.cp_T(data[i], state.T);
            lambdaX[i] := Common.SingleGasNasa.thermalConductivityEstimate(
                Cp=cp[i],
                eta=
            eta[i], method=method);
        end for;
        lambda := lowPressureThermalConductivity(massToMoleFractions(state.X,
                                     fluidConstants[:].molarMass),
                             state.T,
                             fluidConstants[:].criticalTemperature,
                             fluidConstants[:].criticalPressure,
                             fluidConstants[:].molarMass,
                             lambdaX);
        annotation (smoothOrder=2);
        end thermalConductivity;

      annotation (
            Documentation(
         info=\"<html>
<p>Extend of Modelica.Media.IdealGases.Common.MixtureGasNasa with <b> modified Eucken </b> method as default for thermalConductivity function.<br>
If this is not intended use Modelica.Media.IdealGases.Common.MixtureGasNasa as a base instead!
 <code><font style=\\\"color: #0000ff; \\\">&nbsp;</font></code></p> </br> <br> </br>
<table cellspacing=\\\"2\\\" cellpadding=\\\"0\\\" border=\\\"0\\\"><tr>
<td><p><b>Author:</b> </p></td>
<td><p><a href=\\\"mailto:julien.bonifay@siemens.com\\\">Julien Bonifay</a> </p></td>
<td><p><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Checked by:        </b> </p></td>
<td><p><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </p></td>
<td><p><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z000PMEA\\\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Protection class:</b> </p></td>
<td><b>internal</b></td>
<td></td>
</tr>
<tr>
<td><p><b>Used Dymola version:</b> </p></td>
<td></td>
<td></td>
</tr>
</table>
<p> Copyright &AMP;copy 2007 Siemens AG, PG EIP12. All rights reserved.</p>
<p>This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> </p>
</html>\",   revisions=\"<html>
                      <ul>
                             <li> October 2011,  Julien Bonifay
                       </ul>
                        </html>\"));
      end MixtureGasNasa;

      package SingleGasNasa

      import Modelica.Medi" + "a.IdealGases.*;

        extends Modelica.Media.IdealGases.Common.SingleGasNasa;

        redeclare replaceable function thermalConductivity
          \"thermal conductivity of gas\"
        extends Modelica.Icons.Function;
        input ThermodynamicState state \"thermodynamic state record\";
        output ThermalConductivity lambda \"Thermal conductivity\";
        input Integer method=2 \"1: Eucken Method, 2: Modified Eucken Method\";
        algorithm
        assert(fluidConstants[1].hasCriticalData,
        \"Failed to compute thermalConductivity: For the species \\\"\" + mediumName + \"\\\" no critical data is available.\");
        lambda := thermalConductivityEstimate(specificHeatCapacityCp(state),
          dynamicViscosity(state), method=method);
        annotation (smoothOrder=2);
        end thermalConductivity;

      annotation (
            Documentation(
         info=\"<html>
<p>Extend of Modelica.Media.IdealGases.Common.SingleGasNasa with modified Eucken method as default for thermal conductivity function.</p>
<table cellspacing=\\\"2\\\" cellpadding=\\\"0\\\" border=\\\"0\\\"><tr>
<td><p><b>Author:</b> </p></td>
<td><p><a href=\\\"mailto:julien.bonifay@siemens.com\\\">Julien Bonifay</a> </p></td>
<td><p><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Checked by:</b> </p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p><br/><br/><br/><br/><br/><br/><br/><br/><b>Protection class:</b> </p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p><br/><br/><br/><br/><br/><br/><br/><br/><b>Used Dymola version:</b> </p></td>
<td></td>
<td></td>
</tr>
</table>
<p><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>Copyright &AMP;copy 2007 Siemens AG, PG EIP12. All rights reserved.</p>
<p><br/><br/><br/><br/>This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> </p>
</html>\",   revisions=\"<html>
                      <ul>
                             <li> October 2011,  Julien Bonifay
                       </ul>
                        </html>\"));
      end SingleGasNasa;
    end Common;

    package ExhaustGas
      \"SiemensPower: Exhaust gas (6 components) for HRSGs\"
      extends SiemensPower.Media.Common.MixtureGasNasa(
        mediumName=\"Exhaust gas with Ar, CO2, H20, N2, O2, and SO2\",
        data={Modelica.Media.IdealGases.Common.SingleGasesData.Ar,Modelica.Media.
            IdealGases.Common.SingleGasesData.CO2,Modelica.Media.IdealGases.Common.
            SingleGasesData.H2O,Modelica.Media.IdealGases.Common.SingleGasesData.N2,
            Modelica.Media.IdealGases.Common.SingleGasesData.O2,Modelica.Media.
            IdealGases.Common.SingleGasesData.SO2},
        fluidConstants={Modelica.Media.IdealGases.Common.FluidData.Ar,Modelica.
            Media.IdealGases.Common.FluidData.CO2,Modelica.Media.IdealGases.Common.
            FluidData.H2O,Modelica.Media.IdealGases.Common.FluidData.N2,Modelica.
            Media.IdealGases.Common.FluidData.O2,Modelica.Media.IdealGases.Common.
            FluidData.SO2},
        substanceNames={\"Argon\",\"Carbone dioxide\",\"Water\",\"Nitrogen\",\"Oxygen\",
            \"Sulphur dioxide\"},
        reference_X={0.01,0.06,0.05,0.74,0.14,0.0},
        excludeEnthalpyOfFormation=false);

      record Index \"Indices for exhaust components\"
      constant Integer Ar=1 \"Index for argon\";
      constant Integer CO2=2 \"Index for carbon dioxide\";
      constant Integer H2O=3 \"Index for water\";
      constant Integer N2=4 \"Index for nitrogen\";
      constant Integer O2=5 \"Index for oxygen\";
      constant Integer SO2=6 \"Index for sulphur dioxide\";
      end Index;

    annotation (
          Documentation(
       info=\"<HTML>
                    <p>This ideal gas is a model for a flue gas composed as an ideal mixture of the following ideal gases:
                        <ul>
                             <li> Argon
                             <li> Carbon dioxide
                             <li> Water
                             <li> Nitrogen
                             <li> Oxygen
                             <li> Sulphur dioxide
                       </ul>
                    </p>
                   </HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
                      <ul>
                             <li> January 2007,  Haiko Steuer
                       </ul>
                        </html>\"));
    end ExhaustGas;

    package ExhaustGasSingleComponent
      \"SiemensPower: Exhaust gas(single component) for HRSGs\"
      extends SiemensPower.Media.Common.SingleGasNasa(
                                                  mediumName=\"Exhaust gas(single component) for HRSGs\",
    data=SiemensPower.Media.IdealGasData.ExhaustGasSingleComponent,
    fluidConstants={SiemensPower.Media.IdealGasData.ExhaustGasSingleComponentConstants});
    annotation (
          Documentation(
       info=\"<HTML>
                    <p>This ideal gas flue gas is constructed such that T=0degC at h=0 and the thermodynamic behavior equals a composition of:
                        <ul>
                             <li> Argon: 0.01
                             <li> Carbon dioxide: 0.06
                             <li> Water: 0.05
                             <li> Nitrogen: 0.74
                             <li> Oxygen: 0.14
                             <li> Sulphur dioxide: 0.00
                       </ul>
                       It is computed as a <b>single component</b> ideal gas.
                    </p>
                   </HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                               <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
                      <ul>
                             <li> January 2007 by Haiko Steuer
                       </ul>
                        </html>\"));
    end ExhaustGasSingleComponent;

    package IdealGasData
      \"Ideal gas data based on the NASA Glenn coefficients\"
      extends Modelica.Icons.Library;

       constant Modelica.Media.IdealGases.Common.DataRecord
        FlueGasSingleComponent(
        name=\"Simple Flue Gas\",
        MM=0.0299435,
        Hf=2263.289e3,
        H0=2000e3,
        Tlimit=2500,
        alow={0,0,3.29882, 0.00130972, -2.55024e-7, 0, 0},
        blow={0,4.256},
        ahigh={0,0,3.29882, 0.00130972, -2.55024e-7, 0, 0},
        bhigh={0,4.256},
        R=277.672);

      constant Modelica.Media.IdealGases.Common.SingleGasNasa.FluidConstants
        FlueGasSingleComponentConstants(
                           chemicalFormula =        \"unknown\",
                           iupacName =              \"unknown\",
                           structureFormula =       \"unknown\",
                           casRegistryNumber =      \"unknown\",
                           meltingPoint =            63.15,
                           normalBoilingPoint =      77.35,
                           criticalTemperature =    126.20,
                           criticalPressure =        33.98e5,
                           criticalMolarVolume =     90.10e-6,
                           acentricFactor =           0.037,
                           dipoleMoment =             0.0,
                           molarMass =              FlueGasSingleComponent.MM,
                           hasDipoleMoment =       true,
                           hasIdealGasHeatCapacity=true,
                           hasCriticalData =       true,
                           hasAcentricFactor =     true);

      constant Modelica.Media.IdealGases.Common.DataRecord
        ExhaustGasSingleComponent(
        name=\"Simple Exhaust Gas\",
        MM=0.0284251,
        Hf=2269.175e3,
        H0=2000e3,
        Tlimit=2500,
        alow={0,0,3.2236, 0.0011013, -2.01923e-7, 0, 0},
        blow={0,4.61},
        ahigh={0,0,3.2236, 0.0011013, -2.01923e-7, 0, 0}," + "
        bhigh={0,4.61},
        R=292.505);

      constant Modelica.Media.IdealGases.Common.SingleGasNasa.FluidConstants
        ExhaustGasSingleComponentConstants(
                           chemicalFormula =        \"unknown\",
                           iupacName =              \"unknown\",
                           structureFormula =       \"unknown\",
                           casRegistryNumber =      \"unknown\",
                           meltingPoint =            63.15,
                           normalBoilingPoint =      77.35,
                           criticalTemperature =    126.20,
                           criticalPressure =        33.98e5,
                           criticalMolarVolume =     90.10e-6,
                           acentricFactor =           0.037,
                           dipoleMoment =             0.0,
                           molarMass =              ExhaustGasSingleComponent.MM,
                           hasDipoleMoment =       true,
                           hasIdealGasHeatCapacity=true,
                           hasCriticalData =       true,
                           hasAcentricFactor =     true);

    annotation (
          Documentation(
       info=\"<HTML>
                    <p>This package contains data for simple ideal gases<br>
                    </p>
                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                               <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
                      <ul>
                             <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>\"));

    end IdealGasData;

    package IntH2O \"Water/steam table functions according to intH2O\"
      function p_rhoh \"p(rho,h)\"
        import SI = SiemensPower.Units;
       input SI.Density rho \"Density\";
        input SI.SpecificEnthalpy h \"Specific enthalpy\";

         output SI.AbsolutePressure p \"Pressure\";

      protected
      SI.Density p_rho=rho;
      SI.SpecificEnthalpy p_h=h;

       external \"C\" p = H2O_p_Rh(p_rho,p_h);

       annotation (derivative=der_p_rhoh,
          Documentation(
       info=\"<HTML>
                    <p>This function returns the pressure as function of rho and h. The water/steam functions are computed according to inth2o.
                    </p>
                    <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                           <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
                   </HTML>\",
          revisions=\"<html>
                      <ul>
                              <li> December 2006 by Kilian Link
                       </ul>
                        </html>\"),
                   Library={\"intH2O98\"},
                 derivative = der_p_rhoh);
      end p_rhoh;

      function rho_ph_dpdh
        \"rho, drdp and drdh as function of p and h\"
        import SI = SiemensPower.Units;
        input SI.Pressure p \"Pressure\";
        input SI.SpecificEnthalpy h \"Specific enthalpy\";

        output SI.Density rho \"Density\";
        output Real drhodp( unit = \"kg/(m3.Pa)\")
          \"partial derivative of rho wrt p\";
        output Real drhodh( unit = \"(kg.kg)/(m3.J)\")
          \"partial derivative of rho wrt h\";
      protected
      Real p_drhodp[1]( unit = \"kg/(m3.Pa)\");
      Real p_drhodh[1]( unit = \"(kg.kg)/(m3.J)\");

      algorithm
        (rho,p_drhodp,p_drhodh):=drho_p_dp_p_dh(p,h);
        drhodp:=p_drhodp[1];
        drhodh:=p_drhodh[1];

      protected
      function drho_p_dp_p_dh
        input SI.Pressure p;
        input SI.SpecificEnthalpy h;

        output SI.Density rho;
        output Real drho_dp[1]( unit = \"kg/(m3.Pa)\");
        output Real drho_dh[1](  unit = \"(kg.kg)/(m3.J)\");

        protected
        SI.SpecificEnthalpy p_h = h;
        SI.Pressure p_p=p;

        external \"C\" rho =
                          dH2O_R_ph(p_p,p_h,drho_dp,drho_dh);

        annotation(Library={\"intH2O98\"});
      end drho_p_dp_p_dh;

      annotation (
          Documentation(
       info=\"<HTML>
                    <p>This function returns the density as function of p and h
                  including partial derivatives. The water/steam functions are computed according to inth2o.
                    </p>
                    <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                           <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
                   </HTML>\",
          revisions=\"<html>
                      <ul>
                              <li> December 2006 by Kilian Link
                       </ul>
                        </html>\"));

      end rho_ph_dpdh;

      function T_rhoh \"T(rho,h)\"
        import SI = SiemensPower.Units;

        input SI.Density rho \"Density\";
        input SI.SpecificEnthalpy h \"Specific enthalpy\";

        output Real T \"Temperature\";

      protected
      SI.Density p_rho=rho;
      SI.SpecificEnthalpy p_h=h;

      external \"C\" T = H2O_T_Rh(p_rho,p_h);

       annotation (
          Documentation(
       info=\"<HTML>
                    <p>This function returns the temperature as function of rho and h. The water/steam functions are computed according to inth2o.
                    </p>
                    <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                           <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
                   </HTML>\",
          revisions=\"<html>
                      <ul>
                              <li> December 2006 by Kilian Link
                       </ul>
                        </html>\"),
                 Library={\"intH2O98\"});
      end T_rhoh;
    annotation(Documentation(
     info=\"<HTML>
                    <p>Water-steam table functions from inth2o
                    </p>
<b>Important note:</b>
                    From the IntH2O/library folder
                    <ul>
                      <li> the library file inth2O98.lib has to be copied to C:/Dymola/work
                            (if you want to chose another location, you h" + "ave to modify the corresponding library-annotations in the models)
                      <li> the header file inth2O.h has to be present in your working directory.
</ul>

<p>
<b>For information only:</b> The following inth2o functions are called:
<ul>
<li>double  H2O_p_Rh (double*,double*);
<li>double dH2O_p_Rh (double*,double*,double*,double*);
<li>double  H2O_T_Rh (double*,double*);
<li>double dH2O_T_Rh (double*,double*,double*,double*);
<li>double  H2O_R_ph (double*,double*);
<li>double dH2O_R_ph (double*,double*,double*,double*);
</ul>

                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td> <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",
        revisions=\"<html>
                      <ul>
                              <li> December 2006 by Kilian Link
                       </ul>
                        </html>\"));
    end IntH2O;

    package TTSE \"Water/steam table functions according to TTSE\"

      package Utilities
        function rho_ph \"rho(p,h)\"
          import SI = SiemensPower.Units;

          input SI.Pressure p \"Pressure\";
          input SI.SpecificEnthalpy h \"Specific enthalpy\";
          input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";

          output SI.Density rho \"Density\";

          external \"C\" rho =
                           TTSE_rho_ph(p,h,phase);
          annotation(Library={\"TTSEmoI\", \"TTSE\"},derivative(noDerivative=phase)=der_rho_ph, Inline=false,
            LateInline=true,
            Documentation(info=\"<html>
<p>This function returns the density as function of p and h. The water/steam functions are computed according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
                      <ul>
                              <li> May 2011 by Julien Bonifay
                       </ul>
                        </html>\"));

        end rho_ph;

        function rho_ph_dh \"rho(p,h)/dh\"
          import SI = SiemensPower.Units;
            input SI.Pressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
            input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            output Real drho_dh \"Partial derivative drho/dh\";

            external \"C\" drho_dh =
                                 TTSE_d1_rho_ph_dh(
                 p,
                  h, phase);
            annotation (Library={\"TTSEmoI\", \"TTSE\"},derivative(noDerivative=phase)=der_drhodh, Documentation(info=\"<html>
<p>This function returns the partial derivative of rho wrt h versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> May 2011 by Julien Bonifay
</ul>
</html>\"));

        end rho_ph_dh;

        function rho_ph_dp \"rho(p,h)/dp\"
          import SI = SiemensPower.Units;
            input SI.Pressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
            input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            output Real drho_dp \"Partial derivative drho/dp\";

            external \"C\" drho_dp =
                                 TTSE_d1_rho_ph_dp(
                  p,
                  h,phase);
            annotation (Library={\"TTSEmoI\", \"TTSE\"},derivative(noDerivative=phase)=der_drhodp, Documentation(info=\"<html>
<p>This function returns the partial derivative of rho wrt p versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> May 2011 by Julien Bonifay
</ul>
</html>\"));

        end rho_ph_dp;

        function T_ph \"T(p,h)\"
          import SI = SiemensPower.Units;
          input SI.Pressure p \"Pressure\";
          input SI.SpecificEnthalpy h \"Specific enthalpy\";
          input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
          output SI.Temperature T \"Temperature\";

          external \"C\" T =
                          TTSE_T_ph(p,h,phase);

          annotation(Library={\"TTSEmoI\", \"TTSE\"},derivative(noDerivative=phase)=der_T_ph, Documentation(info=\"<html>
<p>This function returns the temperature as function of p and h. The water/steam functions are computed according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",       revisions=\"<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>\"));

        end T_ph;

        function der_rho_ph \"Time derivative of rho(p,h)\"
          import SI = SiemensPower.Units;

         input SI.Pressure p \"Pressure\";
         input SI.Sp" + "ecificEnthalpy h \"Specific enthalpy\";
         input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
         input Real der_p \"time derivative of pressure\";
         input Real der_h \"time derivative of specific enthalpy\";
         output Real der_rho \"time derivative of density\";

        algorithm
             der_rho:= SiemensPower.Media.TTSE.Utilities.rho_ph_dh(p, h,phase)*der_h +
            SiemensPower.Media.TTSE.Utilities.rho_ph_dp(p, h,phase)*der_p;

          annotation (Documentation(info=\"<html>
<p>This function returns the time derivative of the density as function of p and h according to the chain rule. The partial derivatives are build with help of TTSE functions. </p>
</html>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
                      <ul>
                              <li> May 2011 by Julien Bonifay
                       </ul>
                        </html>\"));
        end der_rho_ph;

        function der_drhodh \"Time derivative for drho_dh function\"
          import SI = SiemensPower.Units;
          import SiemensPower;

           input SI.Pressure p \"Pressure\";
           input SI.SpecificEnthalpy h \"Specific Enthalpy\";
           input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
           input Real der_p \"Time derivative of p\";
           input Real der_h \"Time derivative of h\";
           output Real der_drdh \"Time derivative of drho/dh\";

        algorithm
          der_drdh := SiemensPower.Media.TTSE.Utilities.rho_ph_d2h(p, h)*der_h +
            SiemensPower.Media.TTSE.Utilities.rho_ph_d2ph(p, h)*der_p;

        annotation(Documentation(info=\"<html>
<p>This function returns the time derivative of drho/dh with the help of TTSE functions.
                    </p>
</html>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> May 2011 by Julien Bonifay
</ul>
</html>\"));
        end der_drhodh;

        function der_drhodp \"Time derivative for drho_dp function\"
          import SI = SiemensPower.Units;
            input SI.Pressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
            input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            input Real der_p \"Time derivative of p\";
            input Real der_h \"Time derivative of h\";
            output Real der_drdp \"Time derivative of drho/dp\";

        algorithm
          der_drdp := SiemensPower.Media.TTSE.Utilities.rho_ph_d2p(p, h)*der_p +
            SiemensPower.Media.TTSE.Utilities.rho_ph_d2ph(p, h)*der_h;

        annotation(Documentation(info=\"<html>
<p>This function returns the time derivative of drho/dp with the help of TTSE functions.
                    </p>
</html>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",     revisions=\"<html>
<ul>
<li> May 2011, by Julien Bonifay
</ul>
</html>\"));
        end der_drhodp;

        function rho_ph_d2h
          \"rho, d2rhodh2, d2rhodhdp as function of p and h\"

          import SI = SiemensPower.Units;
          input SI.Pressure p \"Pressure\";
          input SI.SpecificEnthalpy h \"Specific enthalpy\";

          output Real d2rho_dh;

          external \"C\" d2rho_dh =
                                TTSE_d2_rho_ph_dh(p,h);
           annotation (Library={\"TTSEmoI\", \"TTSE\"}, Documentation(info=\"<html>
<p>This function returns the second partial derivative of rho wrt h versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));

        end rho_ph_d2h;

        function rho_ph_d2p
          \"rho, d2rhodp2, d2rhodhdp as function of p and h\"

          import SI = SiemensPower.Units;
          input SI.Pressure p \"Pressure\";
          input SI.SpecificEnthalpy h \"Specific enthalpy\";

          output Real d2rho_dp;

          external \"C\" d2rho_dp =
                                TTSE_d2_rho_ph_dp(p,h);
           annotation (Library={\"TTSEmoI\", \"TTSE\"}, Documentation(info=\"<html>
<p>This function returns the second partial derivative of rho wrtp versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));

        end rho_ph_d2p;

        function rho_ph_d2ph
          \"rho, d2rhodp2, d2rhodhdp as function of p and h\"

          import SI = SiemensPower.Units;
          input SI.Pressure p \"Pressure\";
          input SI.SpecificEnthalpy h \"Specific enthalpy\";

          output Real d2rho_dpdh;

          external \"C\" d2rho_dpdh =
                                  " + "TTSE_d2_rho_ph_dpdh(p,h);
           annotation (Library={\"TTSEmoI\", \"TTSE\"}, Documentation(info=\"<html>
<p>This function returns the second partial derivative of rho wrt p and h versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));

        end rho_ph_d2ph;

        function der_T_ph \"Time derivative of T(p,h)\"
          import SI = SiemensPower.Units;
            input SI.AbsolutePressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
            input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            input Real der_p( unit = \"Pa/s\") \"Time derivative of pressure\";
            input Real der_h( unit = \"J/(kg.s)\")
            \"Time derivative of specific enthalpy\";
            output Real der_T(  unit = \"K/s\") \"Time derivative of temperature\";

        algorithm
          der_T := SiemensPower.Media.TTSE.Utilities.T_ph_dh(p, h,phase)*der_h +
            SiemensPower.Media.TTSE.Utilities.T_ph_dp(p, h,phase)*der_p;

          annotation (Documentation(info=\"<html>
<p>This function returns the time derivative of the temperature as function of p and h according to the chain rule. The partial derivatives are build with help of TTSE functions. </p>
</html>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
                      <ul>
                              <li> May 2011 by Julien Bonifay
                       </ul>
                        </html>\"));
        end der_T_ph;

        function T_ph_dh \"T(p,h)/dh\"
          import SI = SiemensPower.Units;
            input SI.Pressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
             input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            output Real dT_dh \"Partial derivative dT/dh\";

            external \"C\" dT_dh =
                               TTSE_d1_T_ph_dh(
                 p,
                  h,phase);
            annotation (Library={\"TTSEmoI\", \"TTSE\"}, Documentation(info=\"<html>
<p>This function returns the partial derivative of T wrt h versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",       revisions=\"<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>\"));

        end T_ph_dh;

        function T_ph_dp \"T(p,h)/dp\"
          import SI = SiemensPower.Units;
            input SI.Pressure p \"Pressure\";
            input SI.SpecificEnthalpy h \"Specific Enthalpy\";
            input Integer phase=0
            \"2 for two-phase, 1 for one-phase, 0 if not known\";
            output Real dT_dp \"Partial derivative dT/dp\";

            external \"C\" dT_dp =
                               TTSE_d1_T_ph_dp(p,h,phase);
            annotation (Library={\"TTSEmoI\", \"TTSE\"}, Documentation(info=\"<html>
<p>This function returns the partial derivative of T wrt p versus p and h according to TTSE. </p>
</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:\\\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",       revisions=\"<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>\"));

        end T_ph_dp;
      end Utilities;
    annotation(Documentation(
     info=\"<html>
<p>Direct functions (utilities) and Modelica Media for Water/steam table TTSE (latest version 2.4).</p>
<p><b>Important note:</b> Some libraries are needed and can be found in SiemensPower\\\\Utilities\\\\Libs. The libraries are: </p>
<p><ul>
<li>TTSEMoI.lib and TTSE.lib has to be copied to a library folder (for example Dymola 7.4\\\\bin\\\\lib). Another library directory can also be set by editing the file Dymola 7.4\\\\bin\\\\build.bat </li>
<li>TTSEDMoI.dll has to be copied to the SYSTEM32 folder of Windows or to the Dymola Work Directory.</li>
<li>TTSE.dll has to be copied to the SYSTEM32 folder of Windows or to the Dymola Work Directory.</li>
<li>IMPORTANT: TTSE doesn&apos;t need anymore to be initialized in Dymola. The initialization is done automatically one time during the first TTSE function call.</li>
</ul></p>
</html>\",
        revisions=\"<html>
                      <ul>
                              <li> May 2011 by Julien Bonifay
                       </ul>
                        </html>\"));
    end TTSE;
  annotation (Documentation(info=\"<html>
This package contains medium models.
</html>\"));
  end Media;

  package Utilities \"Parts and basics of components\"
    package BaseClasses \"Partial models\"
      partial model BaseTube
        \"Base class for spatial discretized tubes\"
        import SI = SiemensPower.Units;
        extends SiemensPower.Utilities.BaseClasses.PartialTwoPortTransport(pIn_start=pOut_start);
        constant Real g=Modelica.Constants.g_n;
        constant Real pi=Modelica.Constants.pi;

        parameter Integer numberOfNodes(min=2) = 2
          \"Number of nodes for thermal variables\";
        parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
          \"Geometry of tube\" annotation(Dialog(group=\"Geometry and correlations\"));

        // Initialization
        parameter Boolean initializeInletPressure = true
          \"add steady state equation for pressure\"  annotation(Dialog(tab=\"Initialization\"));
        parameter Boolean initializeSteadyStateEnthalpies=true
          \"lets initialize der(h)=0\" annotation(evaluate=true, Dialog(tab=\"Initialization\"));
        parameter Boolean initializeSteadyStateInletEnthalpy=true
          \"steady state initial condition for input enthalpy\" annotation(evaluate=true, Dialog(tab=\"Initialization\", enable=initializeSteadyStateEnthalpies));
        parameter SI.SpecificEnthalpy h_start[numberOfNodes] = hIn_start*ones(numberOfNodes"
         + ") + (hOut_start-hIn_start)*SiemensPower.Utilities.Functions.my_linspace(1/numberOfNodes,1,numberOfNodes)
          \"guess values for initial enthalpy vector\"  annotation(Dialog(tab=\"Advanced\", group=\"Initialization\"));
        parameter SI.HeatFlowRate Q_flow_start[numberOfNodes] = (hOut_start-hIn_start)*m_flow_start/(geoPipe.Nt*numberOfNodes)*ones(numberOfNodes)
          \"Detailed start values for heat flow\"  annotation(Dialog(tab=\"Advanced\", group=\"Initialization\"));

        // Advanced
        parameter SI.Volume additionalVolume=0
          \"Additional volume to total tubes volumes\"annotation(Dialog(tab=\"Advanced\"));
        parameter Boolean useDynamicMassBalance=true \"consider mass storage\" annotation(Dialog(tab=\"Advanced\", group=\"Dynamics\"),Evaluate=true);
        parameter Boolean considerDynamicMomentum=true
          \"der(m_flow) accounted for, be careful!\"  annotation(Dialog(tab=\"Advanced\", group=\"Dynamics\"),evaluate=true);
        parameter Boolean considerDynamicPressure=false
          \"With der(p)/d in enthalpy balance (for shock waves)\"  annotation(Dialog(tab=\"Advanced\", group=\"Dynamics\"),Evaluate=true);
        parameter SI.Area heatedArea=geoPipe.Nt*geoPipe.L*Modelica.Constants.pi*diameterInner
          \"Total Area for heat transfer\" annotation(Dialog(tab=\"Advanced\", group=\"Inner heat transfer\"));

        final parameter SI.Length diameterInner = geoPipe.d_out - 2*geoPipe.s;
        final parameter SI.Length dz= geoPipe.L/numberOfNodes;
        final parameter SI.Volume V = geoPipe.A*geoPipe.L+additionalVolume/geoPipe.Nt;
        final parameter SI.Area A = geoPipe.A * (1.0+ additionalVolume/(geoPipe.Nt*geoPipe.A*geoPipe.L));
        final parameter SI.Volume VTotal = geoPipe.Nt*V;
        final parameter SI.Volume VCell= V/numberOfNodes annotation(Evaluate=true);
        final parameter Real sinphi = geoPipe.H / geoPipe.L;

      //  Medium.BaseProperties fluid[numberOfNodes](each preferredMediumStates=preferredStates,
      //                            p(start=SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes)),
      //                            h(start=h_start),
      //                            each Xi(start=XIn_start[1:Medium.nXi]));
        SI.MassFlowRate m_flows[numberOfNodes](each start=m_flow_start/geoPipe.Nt);
        SI.Density d_av(start=sum(d_start)/numberOfNodes);
        SI.SpecificVolume vol_av(start=1/SiemensPower.Media.TTSE.Utilities.rho_ph(0.5*(pIn_start+pOut_start), 0.5*(hIn_start+hOut_start)));
        SI.Pressure dpfric(start= dpFric_start);
        SI.Pressure dphyd(start=dpHyd_start);
        SI.SpecificEnthalpy hFluid[numberOfNodes](start=h_start);
        SI.Pressure pFluid[numberOfNodes]( start=SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes));

      protected
        final parameter SI.Pressure dpHyd_start = g*geoPipe.H*sum(SiemensPower.Media.TTSE.Utilities.rho_ph(SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes),h_start));
        final parameter SI.Pressure dpFric_start = max(0.0, pIn_start-pOut_start-dpHyd_start);
        final parameter SI.Temperature T_start[numberOfNodes]=SiemensPower.Media.TTSE.Utilities.T_ph(SiemensPower.Utilities.Functions.my_linspace(pIn_start, pOut_start, numberOfNodes),h_start)
          \"start values for fluid temperatures\";
        final parameter SI.Density d_start[numberOfNodes]=SiemensPower.Media.TTSE.Utilities.rho_ph(SiemensPower.Utilities.Functions.my_linspace(pIn_start, pOut_start, numberOfNodes),h_start);
        final parameter SI.HeatFlux q_start =  m_flow_start*(hOut_start-hIn_start)/heatedArea;
        SI.MassFlowRate m_flowsZero(start=m_flow_start/geoPipe.Nt);
        SI.Temperature T[numberOfNodes](start=T_start);
        SI.Density d[numberOfNodes](start=d_start);
        SI.SpecificVolume vol[numberOfNodes](each start=1/SiemensPower.Media.TTSE.Utilities.rho_ph(0.5*(pIn_start+pOut_start), 0.5*(hIn_start+hOut_start)));
        SI.SpecificHeatCapacity cp[numberOfNodes];
        SI.DynamicViscosity eta[numberOfNodes];
        SI.ThermalConductivity lambda[numberOfNodes];
        SI.HeatFlowRate E_flows[numberOfNodes](start=-Q_flow_start);
      //  SI.MassFlowRate M_flows[numberOfNodes,Medium.nXi];
        replaceable SI.HeatFlux qHeating[numberOfNodes](each start=q_start)=zeros(numberOfNodes);

      initial equation

        // h
       if (useEnergyStorage) then
        if (initializeSteadyStateInletEnthalpy and initializeSteadyStateEnthalpies) then
              der(hFluid[1])=0;
        end if;
        if (initializeSteadyStateEnthalpies) then
            for j in 2:numberOfNodes loop
              der(hFluid[j]) = 0;
           end for;
        end if;
        end if;

      //  if (useSubstanceStorage) then
      //    for j in 1:(numberOfNodes) loop
      //     // der(fluid[j].Xi)  = zeros(Medium.nXi);
      //     fluid[j].Xi = XIn_start[1:Medium.nXi];
      //    end for;
      // end if;

      equation
        // thermodynamic properties
        //fluid.d = d;
        //fluid.T = T;
        for j in 1:numberOfNodes loop
            vol[j]=1.0/d[j];
        end for;
        d_av=sum(d)/numberOfNodes;
        vol_av=sum(vol)/numberOfNodes;
        //eta = Medium.dynamicViscosity(fluid.state);
        //cp = Medium.specificHeatCapacityCp(fluid.state);
        //lambda = Medium.thermalConductivity(fluid.state);

        // transport flows
        E_flows[1]= max(0,m_flowsZero) *(inStream(portIn.h_outflow)-hFluid[1])+max(0,-m_flows[1])*(hFluid[2]-hFluid[1]);
      //  M_flows[1,:]= max(0,m_flowsZero) *(inStream(portIn.Xi_outflow)-fluid[1].Xi)+max(0,-m_flows[1])*(fluid[2].Xi-fluid[1].Xi);
        for j in 2:(numberOfNodes-1) loop
            E_flows[j]=max(0,m_flows[j-1])*(hFluid[j-1]-hFluid[j])+max(0,-m_flows[j])*(hFluid[j+1]-hFluid[j]);
      //      M_flows[j,:]=max(0,m_flows[j-1])*(fluid[j-1].Xi-fluid[j].Xi)+max(0,-m_flows[j])*(fluid[j+1].Xi-fluid[j].Xi);
        end for;
        E_flows[numberOfNodes]=max(0,m_flows[numberOfNodes-1])*(hFluid[numberOfNodes-1]-hFluid[numberOfNodes])+max(0,-m_flows[numberOfNodes])*(inStream(portOut.h_outflow)-hFluid[numberOfNodes]);
      //  M_flows[numberOfNodes,:]=max(0,m_flows[numberOfNodes-1])*(fluid[numberOfNodes-1].Xi-fluid[numberOfNodes].Xi)+max(0,-m_flows[numberOfNodes])*(inStream(portOut.Xi_outflow)-fluid[numberOfNodes].Xi);

       // energy + substance balance
        if useEnergyStorage then
          portIn.h_outflow = hFluid[1];
          portOut.h_outflow= hFluid[numberOfNodes];
        end if;
      //  if useSubstanceStorage then
      //    portIn.Xi_outflow = fluid[1].Xi;
      //    portOut.Xi_outflow= fluid[numberOfNodes].Xi;
      //  end if;
        for j in 1:numberOfNodes loop
           if useEnergyStorage then
              if considerDynamicPressure then
                 VCell*(d[j]*der(hFluid[j])-der(pFluid[j])) = E_flows[j] + heatedArea*qHeating[j]/(numberOfNodes*geoPipe.Nt);
              else
                 VCell*d[j]*der(hFluid[j]) = E_flows[j] + heatedArea*qHeating[j]/(numberOfNodes*geoPipe.Nt);
              end if;
           else
              hFluid[j] = Modelica.Fluid.Utilities.regStep(m_flowsZero, inStream(portIn.h_outflow), inStream(portOut.h_outflow));
           end if;
      //     if useSubstanceStorage then
      //        VCell*fluid[j].d*der(fluid[j].Xi) = M_flows[j,:];
      //     else
      //        fluid[j].Xi = Modelica.Fluid.Utilities.regStep(m_flowsZero, inStream(portIn.Xi_outflow), inStream(portOut.Xi_outflow));
      //     end if;
        end for;

        annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
                  -100},{100,100}}), graphics={Rectangle(
                extent={{-90,40},{92,-40}},
                lineColor={0,0,0},
                pattern=LinePattern.None,
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={0,149,255}), Text(
                extent={{-100,-50},{100,-90}},
                lineColor={0,0,0},
                textString=\"%name\")}),
          Documentation(info=\"<HTML>
<p>This base class describes the geometry and most important variables for the water/steam flow in a pipe.<br>
It will be a 1-dimensional flow model.
In the derived class, the following quantities/equations have to be set:<br>
<ul>
<li> pressure(s)
<li> mass flow rate(s) + momentum balance(s) incl hydrostatic and friction pressure drop
<li> mass densities d[1], ...d[numberOfNodes] for each cell + continuity equation(s)
<li> specific enthalpies hFluid[1], ..., hFluid[numberOfNodes] (energy balances)
<li>
</ul>
<p>
</HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>\"),Diagram);
      end BaseTube;

      partial model PartialTwoPortTransport
        \"Base class for components with two fluid ports\"
    " + "    import SI = SiemensPower.Units;

        SI.SpecificEnthalpy hIn(start=hIn_start) \"actual state at portIn\";
        SI.SpecificEnthalpy hOut(start=hOut_start) \"actual state at portOut\";

      // Medium
      //  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
      //    constrainedby Modelica.Media.Interfaces.PartialMedium
      //           annotation (choicesAllMatching = true);

        parameter Boolean preferredStates=true
          \"Try to select preferred medium states\"                                      annotation(Dialog(tab=\"Advanced\"));

      // Initializatin parameters
       parameter SiemensPower.Units.MassFlowRate m_flow_start=1
          \"Guess value for mass flow rate\"                                                 annotation(Dialog(tab=\"Initialization\"));

        parameter SI.AbsolutePressure pIn_start = 1e5
          \"Start value of inlet pressure\"
          annotation(Dialog(tab = \"Initialization\"));
        parameter SI.AbsolutePressure pOut_start = 1e5
          \"Start value of outlet pressure\"
          annotation(Dialog(tab = \"Initialization\"));

       parameter Boolean useTemperatureStartValue = false
          \"Use T_start if true, otherwise h_start\"
          annotation(Dialog(tab = \"Initialization\"), Evaluate=true);

        parameter SI.SpecificEnthalpy hIn_start= 1000e3;
      //    if useTemperatureStartValue then
      //       Medium.specificEnthalpy_pTX(pIn_start, TIn_start,XIn_start)
      //    else Medium.h_default
      //    \"Start value of specific enthalpy\"
      //    annotation(Dialog(tab = \"Initialization\", enable = not useTemperatureStartValue));
        parameter SI.SpecificEnthalpy hOut_start=1000e3;
      //    if useTemperatureStartValue then Medium.specificEnthalpy_pTX(pOut_start, TOut_start,XOut_start)
      //      else Medium.h_default
      //    \"Start value of specific outlet enthalpy\"
      //    annotation(Dialog(tab = \"Initialization\", enable = not useTemperatureStartValue));

        parameter SI.Temperature TIn_start=SiemensPower.Media.TTSE.Utilities.T_ph(pIn_start, hIn_start);
        //  if useTemperatureStartValue then Medium.reference_T else Medium.temperature_phX(pIn_start,hIn_start)
        //  \"Start value of temperature\"
        //  annotation(Dialog(tab = \"Initialization\", enable = useTemperatureStartValue));
        parameter SI.Temperature TOut_start=SiemensPower.Media.TTSE.Utilities.T_ph(pOut_start, hOut_start);
        //  if useTemperatureStartValue then Medium.reference_T else Medium.temperature_phX(pOut_start,hOut_start)
        //  \"Start value of  outlet temperature\"
        //  annotation(Dialog(tab = \"Initialization\", enable = useTemperatureStartValue));

      //  parameter Medium.MassFraction XIn_start[Medium.nX] = Medium.reference_X
      //    \"Start value of mass fractions m_i/m\"
      //    annotation (Dialog(tab=\"Initialization\", enable=Medium.nXi > 0));
      //  parameter Medium.MassFraction XOut_start[Medium.nX] = Medium.reference_X
      //    \"Start value of mass fractions m_i/m\"
      //    annotation (Dialog(tab=\"Initialization\", enable=Medium.nXi > 0));

        parameter Boolean useSubstanceStorage=false
          \"consider composition storage\" annotation(Dialog(tab=\"Advanced\", group=\"Dynamics\"));

        parameter Boolean useEnergyStorage=true
          \"consider energy storage (else: isenthalpic transport)\"                                        annotation(Dialog(tab=\"Advanced\", group=\"Dynamics\"));

        SiemensPower.Interfaces.FluidPort_a portIn( m_flow(start=m_flow_start), h_outflow(start=hIn_start), p(start=pIn_start))
          \"Inlet port\" annotation (Placement(transformation(extent={{-120,-20},{-80,
                  20}}, rotation=0), iconTransformation(extent={{-120,-20},{-80,20}})));

        SiemensPower.Interfaces.FluidPort_b portOut( m_flow(start=-m_flow_start), h_outflow(start=hOut_start), p(start=pOut_start))
          \"Outlet port\" annotation (Placement(transformation(extent={{120,-20},{80,20}},
                rotation=0), iconTransformation(extent={{120,-20},{80,20}})));

        SI.Pressure dp(start=pIn_start-pOut_start);

        //Medium.ThermodynamicState state_from_a(p(start=pIn_start), T(start=TIn_start))
        //  \"state for medium inflowing through portIn\";
        //Medium.ThermodynamicState state_from_b(p(start=pOut_start), T(start=TOut_start))
        //  \"state for medium inflowing through portOut\";

      equation
      // medium states
      //  state_from_a = Medium.setState_phX(portIn.p, inStream(portIn.h_outflow), inStream(portIn.Xi_outflow));
      //  state_from_b = Medium.setState_phX(portOut.p, inStream(portOut.h_outflow), inStream(portOut.Xi_outflow));
        if noEvent(portIn.m_flow>=0) then
          hIn = inStream(portIn.h_outflow);
        else
          hIn = portIn.h_outflow;
        end if;
        if noEvent(portOut.m_flow>=0) then
          hOut =  inStream(portOut.h_outflow);
        else
          hOut = portOut.h_outflow;
        end if;

        dp = portIn.p - portOut.p;

      //  if (not useSubstanceStorage) then
          // no substance storage
      //    portIn.Xi_outflow = inStream(portOut.Xi_outflow);
      //    portOut.Xi_outflow = inStream(portIn.Xi_outflow);
      //  end if;

       if (not useEnergyStorage) then
          // isenthalpic transport
          portIn.h_outflow = inStream(portOut.h_outflow);
          portOut.h_outflow = inStream(portIn.h_outflow);
       end if;

      //  portIn.C_outflow = inStream(portOut.C_outflow);
      //  portOut.C_outflow = inStream(portIn.C_outflow);

        annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
                  -100},{100,100}}), graphics),
          Documentation(info=\"<HTML>
<p>This base class describes the geometry and most important variables for the fluid flow without storing substance.<br>
In the derived class, the following quantities/equations have to be set:<br>
<ul>
<li> pressure loss dp (e.g. momentum balance)
<li> mass flow rate (e.g. mass balance)
<li> outflow enthalpies (e.g. energy balance)
<li>
</ul>
<p>
</HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                               <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
<ul>
<li> Feb 2009, added by Haiko Steuer
</ul>
</HTML>\"),Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics));
      end PartialTwoPortTransport;
    annotation (Documentation(info=\"<html>
This package contains partial base classes.
</html>\"));
    end BaseClasses;

    package Functions \"Algorithms and external functions\"
      package CharacteristicNumbers

        function NusseltNumber \"Nusselt number\"
          input SiemensPower.Units.CoefficientOfHeatTransfer alpha
            \"Coefficient of heat transfer\";
          input SiemensPower.Units.Length length \"Characteristic length\";
          input SiemensPower.Units.ThermalConductivity lambda
            \"Thermal conductivity\";
          output SiemensPower.Units.NusseltNumber Nu \"Nusselt number\";
        algorithm
          Nu := alpha*length/lambda;
          annotation (Documentation(info=\"Nusselt number Nu = alpha*length/lambda

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                            <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"),          derivative=NusseltNumber_der,
            Documentation(
         info=\"<HTML>
                    <p>This function returns the Nusselt number. It can be used to define the heat transfer coeficient alpha.<br>
                   </HTML>\",
            revisions=\"<html>
                      <ul>
                             <li> June 2007 by Kilian Link
                       </ul>
                        </html>\"));
        end NusseltNumber;

        function ReynoldsNumber \"Reynolds number of fluid flow\"
          input SiemensPower.Units.MassFlowRate m_flow \"Mass flow rate\";
          input Siemen" + "sPower.Units.Length length
            \"Characteristic length (hyd. diam. in pipes)\";
          input SiemensPower.Units.Area A \"Cross sectional area\";
          input SiemensPower.Units.DynamicViscosity eta \"Dynamic viscosity\";
          output SiemensPower.Units.ReynoldsNumber Re \"Reynolds number\";

        algorithm
          Re := abs(m_flow)*length/A/eta;

        annotation (derivative=ReynoldsNumber_der,
            Documentation(
         info=\"<HTML>
                    <p>This function returns the Reynolds number of a fluid flow.<br>
                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td><td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
                      <ul>
                             <li> June 2007 by Kilian Link
                       </ul>
                        </html>\"));
        end ReynoldsNumber;
      end CharacteristicNumbers;

      function lambdaFin \"Lambda(T) for several fin materials\"
          input SiemensPower.Units.Temperature T \"Fin temperature\";
          input String material \"Fin material\";
          output SiemensPower.Units.ThermalConductivity lambdafin
          \"Thermal conductivity of fins\";

      protected
        SiemensPower.Units.Temperature TdegC;  // in degC
        Integer kennz;
        constant Real koeff[11,3] = {
        {60.476, -0.059313,  0.0},
        {60.40493, -3.1676065e-2, -1.1456087e-5},
        {57.39998, -3.5428531e-2, -2.5621113e-11},
        {49.39394, -9.3689067e-3, -2.4917634e-5},
        {44.76868, -1.6871149e-3, -2.5302164e-5},
        {35.49230, +2.0254429e-2, -4.1153893e-5},
        {18.24780, -5.5563054e-3, +1.9862635e-5},
        {25.64450, +1.1233812e-2, -6.6209222e-6},
        {23.79999, +4.0000575e-3, -8.5403705e-11},
        {23.98241, +8.2362918e-3, -5.4947890e-7},
        {17.00000, +1.0000018e-2, -2.1350926e-11}};
                                                    // Standardfunktion DEFAalt
                                                    // St 35.8
                                                    // St 45.8
                                                    // 15 Mo 3
                                                    // 13 CrMo 4.4
                                                    // 10 CrMo 9.10
                                                    // X 8 CrNiTi 18.10
                                                    // X 10 CrMoVNb 9.1
                                                    // X 20 CrMoV 12.1
                                                    // AISI 409
                                                    // AISI 304

      algorithm
       if (T-273.15 < 50.0) then
          TdegC :=50.0;
       elseif (T-273.15 > 700) then
          TdegC :=700;
       else
          TdegC := T-273.15;
       end if;

       if material==\"Standardfunktion DEFAalt\" then
          kennz:=1;
       elseif material==\"St 35.8\" then
          kennz:=2;
       elseif material==\"St 45.8\" then
          kennz:=3;
       elseif material==\"15 Mo 3\" then
          kennz:=4;
       elseif material==\"13 CrMo 4.4\" then
          kennz:=5;
       elseif material==\"10 CrMo 9.10\" then
          kennz:=6;
       elseif material==\"X 8 CrNiTi 18.10\" then
          kennz:=7;
       elseif material==\"X 10 CrMoVNb 9.1\" then
          kennz:=8;
       elseif material==\"X 20 CrMoV 12.1\" then
          kennz:=9;
       elseif material==\"AISI 409\" then
          kennz:=10;
       elseif material==\"AISI 304\" then
          kennz:=11;
       else
          kennz:=1;
       end if;

       lambdafin := koeff[kennz, 1] + koeff[kennz, 2]*TdegC + koeff[kennz, 3]*TdegC^2;

         annotation (derivative=lambdaFin_der,
          Documentation(
       info=\"<HTML>
                    <p>This function returns the thermal conductivity lambda(T) in dependence of the fin temperature.
                   </HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\", revisions=\"<html>
                      <ul>
                             <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>\"));
      end lambdaFin;

      function my_linspace

        input Real x1;
        input Real x2;
        input Integer n;
        output Real y[n];
      algorithm
        if n>1 then
          for i in 1:n loop
            y[i]:=x1+(i-1)/(n-1)*(x2-x1);
          end for;
        else
          y[1]:=x1;
        end if;

      end my_linspace;
    annotation (Documentation(info=\"<html>
This package contains functions.
</html>\"));
    end Functions;

    package HeatTransfer

      model HeatTransfer_constAlpha
        extends SiemensPower.Utilities.HeatTransfer.HeatTransferBaseClass;

         parameter Real heatingSurfaceFactor_set= 1.0 \"factor for A_h\";

      equation
       alpha = alpha_start*ones(numberOfNodes);
       heatingSurfaceFactor = heatingSurfaceFactor_set;
       Psi = 1.0;
        annotation(Documentation(info=\"<html>
Simple heat transfer correlation with constant heat transfer coefficient, used as default component in <a distributed pipe models.
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
      end HeatTransfer_constAlpha;

      partial model HeatTransferBaseClass
        \"Base class for heat transfer correlation in terms of Nusselt number\"
        import SI = SiemensPower.Units;

        replaceable package Medium =
            Modelica.Media.IdealGases.MixtureGases.FlueGasSixComponents
            constrainedby Modelica.Media.Interfaces.PartialMixtureMedium annotation(Dialog(tab=\"Advanced\", enable=false));
        parameter Integer numberOfNodes(min=1)=1
          \"Number of thermal port segments\"                                        annotation(Dialog(tab=\"Advanced\", enable=false));

        parameter SI.Length lengthRe
          \"Characteristic length for Reynolds number\"                                           annotation(Dialog(tab=\"Advanced\", enable=false));
        parameter SI.Length lengthNu \"Characteristic length for Nusselt number\"
                                                                                               annotation(Dialog(tab=\"Advanced\", enable=false));
        parameter SiemensPower.Units.Area ACrossFlow \"Cross flow area\" annotation(Dialog(tab=\"Advanced\", enable=false));
        parameter SI.Area AHeatTransfer \"Total heat transfer area\" annotation(Dialog(tab=\"Advanced\", enable=false));

        parameter SiemensPower.Utilities.Structures.FgzGeo geoFGZ
          \"Flue gas zone parameters\"   annotation(Dialog(tab=\"No input\", enable=false));
        parameter SiemensPower.Utilities.Structures.Fins geoFins
          \"Fin parameters\"                                                        annotation(Dialog(tab=\"No input\", enable=false));
        parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe" + "
          \"Tube parameters\"
              annotation(Dialog(tab=\"No input\", enable=false));

        parameter SI.CoefficientOfHeatTransfer alpha_start=200
          \"Start/constant value of heat transfer coefficient\";

        outer input Real TWall[numberOfNodes] \"Temperature of heat port\";
        input Medium.ThermodynamicState state;
        input Medium.MassFlowRate m_flow;

        Real Re \"Reynolds number\";
        Real Pr \"Prandtl number\";
        Real[numberOfNodes] Nu \"Nusselt number\";
        Medium.SpecificHeatCapacity cp \"Specific heat capacity\";
        Medium.DynamicViscosity eta \"Dynamic viscosity\";
        Medium.ThermalConductivity lambda \"Thermal conductivity\";

      // the following variables have to be set in derived models
       SI.CoefficientOfHeatTransfer[numberOfNodes] alpha(each start=alpha_start)
          \"CoefficientOfHeatTransfer\";
        Real heatingSurfaceFactor \"factor for AHeatTransfer\";
        Real Psi
          \"crossing area shortening factor because of internals (factor for ACrossFlow)\";

      equation
        cp=Medium.specificHeatCapacityCp(state);
        eta = Medium.dynamicViscosity(state);
        lambda = Medium.thermalConductivity(state, method=2);
        Pr = Medium.prandtlNumber(state);
        Re = SiemensPower.Utilities.Functions.CharacteristicNumbers.ReynoldsNumber(
          m_flow,  lengthRe,  Psi * ACrossFlow,  eta);

       // heat transfer
        for i in 1:numberOfNodes loop
            Nu[i] = SiemensPower.Utilities.Functions.CharacteristicNumbers.NusseltNumber(
                     alpha[i], lengthNu, lambda);
        end for;

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
                textString=\"%name\")}),
                               Documentation(info=\"<HTML>
<p>This is a base class for a heat transfer model usable for inner and outer heat transfer.
It is located between a vector of thermal ports on the other hand and on a (vector of) fluid flow(s) on the other hand.
In a derived class you have to specify
                    <ul>
                             <li> Nusselt numbers Nu[numberOfNodes] OR heat transfer coefficients alpha[numberOfNodes] for each thermal port
                             <li> heatingSurfaceFactor (factor for A_h because of fins or s.th.)
                             <li> Psi (factor for ACrossFlow because of internals)
                       </ul>
                    </p>
At the composing level, you have to specify the fluid flow properties:
<ul>
                             <li> fluid temperatures (input T[ns])
                             <li> fluid states [ns]
                             <li> fluid mass flow rates [ns]
                       </ul>
as well as the thermal ports [numberOfNodes].<p>
As a result, you can use the heat flow rate Q_flow[numberOfNodes], which leaves the fluid, and the thermalPort.Q_flow[numberOfNodes], which enters the fluid ports. The difference is due to the
<b>heatloss</b> to ambient.
 </HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\\\"mailto:kilian.link@siemens.com\\\">Kilian Link</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
<ul>
<li> June 2007 by Haiko Steuer
</ul>
</HTML>\"));
      end HeatTransferBaseClass;

      package InnerHeatTransfer
        \"Correlations for heat transfer inside tubes\"
        model SinglePhase \"turbulent single phase flow ~ cp m\"
          extends
            SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransfer;
          extends
            SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase;

        //    parameter SiemensPower.Units.CoefficientOfHeatTransfer alpha0=0.2e3
        //    \"Offset for heat transfer coefficient\";

           final parameter SiemensPower.Units.Area A = Modelica.Constants.pi*0.25*
              diameterInner                                                       *
              diameterInner;

        equation
          isSinglePhase = true;
         // alpha = alpha0 + 0.06*cp*Modelica.Fluid.Utilities.regRoot(abs(m_flow)/A);
         alpha = 0.002*cp*max(20,abs(m_flow)/A);

            // set dummy
           xdo = 0.9;

        annotation (Documentation(info=\"<html>
  This simple inner heat transfer correlation is good for turbulent single phase flow.
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                        <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
        end SinglePhase;
      end InnerHeatTransfer;
      annotation (Documentation(info=\"<html>
Heat transfer correlations
</html>\"));
    end HeatTransfer;

    package PressureLoss \"Friction pressure loss correlations\"
      partial model PartialFriction
        \"Base class for friction pressure loss correlations\"

       parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
          \"geometry parameters of the tube \"                                                     annotation(Dialog(tab=\"Advanced\",enable=false));
       parameter SiemensPower.Units.Length dz
          \"length of tube section for which friction pressure loss is wanted\"                                  annotation(Dialog(tab=\"Advanced\",enable=false));
       parameter Real lambda=0.02
          \"constant friction factor (used for valve friction model only)\";

        input SiemensPower.Units.Pressure p \"pressure\";
        input SiemensPower.Units.SpecificEnthalpy h \"specific enthalpy\";
        input SiemensPower.Units.Density rho \"mass density\";
        input SiemensPower.Units.DynamicViscosity eta \"dynamic viscosoty\";
        input Real steamQuality \"Steam quality\";
        input Real xdo
          \"Critical steam quality, at which the boiling crisis (e.g. dryout) occurs\";
        input SiemensPower.Units.MassFlowRate m_flow \"mass flow rate\";

       SiemensPower.Units.Pressure dp;
       Boolean isSinglePhase;

        annotation (Documentation(info=\"<html>
  Any derived friction pressure loss correlation must define a relation between m_flow and dp, e.g.
dp/dz = ... * m_flow^2/(rho)
<p>
The additive friction coefficient geo.zeta_add should contribute to the pressure loss something similar to
dp/dz = zeta_add/L*rho/2*v^2
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td><td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
      end PartialFriction;

      partial model PartialFrictionSinglePhase
        \"Base class for restricting the choice of friction correlations\"

        annotation (Documentation(info=\"<html>
  Just a label to characterize friction correlations which do not use two phase prop"
         + "erties
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
      end PartialFrictionSinglePhase;

      model RoughnessFlow \"Roughness friction independent from Re\"
        extends SiemensPower.Utilities.PressureLoss.PartialFriction;
        extends SiemensPower.Utilities.PressureLoss.PartialFrictionSinglePhase;

         parameter SiemensPower.Units.MassFlowRate m_flowLaminar=0.001
          \"nominal mass flow for laminar limit\";
         final parameter SiemensPower.Units.Length diameterInner = geoPipe.d_out-2*geoPipe.s;
         final parameter SiemensPower.Units.Area A = Modelica.Constants.pi*0.25*diameterInner*diameterInner;
         final parameter Real zeta = (1.14-2*Modelica.Math.log10(geoPipe.r/diameterInner))^(-2)+geoPipe.zeta_add*diameterInner/geoPipe.L;

      equation
        isSinglePhase = true;
       dp/dz = zeta*m_flow*(abs(m_flow)+m_flowLaminar)/(2*rho*A^2*diameterInner);

        annotation (Documentation(info=\"<html>
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                            <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\"));
      end RoughnessFlow;
    end PressureLoss;

    package Structures \"Record definitions with parameter structures\"
      record FgzGeo \"Geometry parameters for a flue gas zone\"
        import SI = SiemensPower.Units;

        parameter SI.Length pt=0.1 \"Transverse pitch between tubes\";
        parameter SI.Length pl=0.1 \"Longitudal pitch between tubes\";
        parameter SI.Length Lw=10 \"Width of flue gas zone\";
        parameter SI.Length Ld=15 \"Depth of flue gas zone > tube's length \";
        parameter SI.Length Lh=5 \"Height of flue gas zone\";
        parameter Integer Nr=1 \"Number of tube layers in bundle\";
        parameter Boolean staggered=true
          \"Staggered tube arrangement instead of inline\";

        annotation (Documentation(info=\"<HTML>
<p>These parameters are needed to specify the geoemtry of a flue gas zone.<p>
The figure shows the meaning of the parameters for a vertical and a horizontal boiler: <br>
<img src=\\\"../Documents/fluegaszone.gif\\\"  alt=\\\"Bild\\\">
<p>
Note that for a fired boiler, the pl parameter is not in use.
</p>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",revisions=\"<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</html>\"));
      end FgzGeo;

      record Fins \"Geometry parameters for fins\"
        import SI = SiemensPower.Units;

        parameter Boolean finned=true \"Is finned tube\";
        parameter Boolean serrated=true \"Is serrated (not solid fins)\" annotation(Dialog(enable=finned));
        parameter SI.Length h=0.01 \"height of fins\" annotation(Dialog(enable=finned));
        parameter SI.Length s=0.001 \"width of fins\" annotation(Dialog(enable=finned));
        parameter SI.Length b=0.005 \"base height \" annotation(Dialog(enable=finned and serrated));
        parameter SI.Length w=0.004 \"segment width\" annotation(Dialog(enable=finned and serrated));
        parameter SI.WaveNumber n=270 \"no of fins per meter\" annotation(Dialog(enable=finned));
       parameter String material=\"X 8 CrNiTi 18.10\" \" fin material\"
          annotation(Dialog(enable=finned), choices(
          choice=\"Standardfunktion DEFAalt\" \"Standardfunktion DEFAalt\",
          choice= \"St 35.8\" \"St 35.8\",
          choice= \"St 45.8\" \"St 45.8\",
          choice= \"15 Mo 3\" \"15 Mo 3\",
          choice= \"13 CrMo 4.4\" \"13 CrMo 4.4\",
          choice= \"10 CrMo 9.10\" \"10 CrMo 9.10\",
          choice= \"X 8 CrNiTi 18.10\" \"X 8 CrNiTi 18.10\",
          choice= \"X 10 CrMoVNb 9.1\" \"X 10 CrMoVNb 9.1\",
          choice= \"X 20 CrMoV 12.1\" \"X 20 CrMoV 12.1\",
          choice= \"AISI 409\" \"AISI 409\",
          choice= \"AISI 304\" \"AISI 304\"));

        annotation (Documentation(info=\"<HTML>
<p>These parameters are needed to specify fin parameters.<p>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                            <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",revisions=\"<html>
<ul>
<li> June 2007, added by Haiko Steuer
</ul>
</html>\"));
      end Fins;

      record PipeGeo \"Geometry parameters for a tube\"
        import SI = SiemensPower.Units;

        parameter Integer Nt=1 \"Number of parallel tubes\";
        parameter SI.Length L=1 \"Length of tube\";
        parameter SI.Length H=0 \"Height difference between outlet and inlet\";
        parameter SI.Length d_out=0.038 \"Outer diameter of the tube\";
        parameter SI.Length s=0.003 \"Thickness of the wall\";
        parameter SI.Length r=0.03e-3
          \"Inner roughness (friction coefficient) of the wall\";
        parameter Real zeta_add=0
          \"Additive friction loss coefficient (for bendings)\";
        parameter Boolean isCylindric=true
          \"assume circular (NOT quadratic) inner cross sectional area\";
        final parameter SI.Area A = (if isCylindric then 0.25*Modelica.Constants.pi else 1.0)*(d_out-2*s)^2
          \"inner cross sectional area\";

       annotation (Documentation(info=\"<HTML>
<p>These parameters are needed to specify the geoemtry of a pipe:
</HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                            <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
     " + "             </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>\"));
      end PipeGeo;

      record PropertiesMetal \"Metal property parameters\"
        import SI = SiemensPower.Units;

        parameter SI.SpecificHeatCapacity cp=540 \"Specific heat capacity\";
        parameter SI.ThermalConductivity lambda=44 \"Thermal conductivity\";
        parameter SI.Density rho=7850 \"Mass density\";

       annotation (Documentation(info=\"<HTML>
<p>These parameters are needed to specify the medium properties of a metal, e.g. in a tube' wall.
   Here, the properties are fixed, i.e. they do <b>not</b> depend on the metal temperature.
  Note that for the wall aggregate, just the <b>product</b> of rho and cp (i.e. the heat capacity per volume) will enter the physics.
</HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\\\"mailto:haiko.steuer@siemens.com\\\">Haiko Steuer</a> </td>
                        <td><a href=\\\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\\\">SCD</a> </td>
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
           For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a> <br>
        </p>
</HTML>\",   revisions=\"<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>\"));
      end PropertiesMetal;
    end Structures;
  annotation (Documentation(info=\"<html>
This package contains basic utilities.
</html>\"));
  end Utilities;

  package Units
    type AbsolutePressure =
                     Modelica.SIunits.AbsolutePressure(start = 5.0e5,min = 0e5,max = 10.0e9, nominal = 5.0e5);
    type Density =   Modelica.SIunits.Density(start = 100,min = 0,max = 9000, nominal = 100);
    type Mass =      Modelica.SIunits.Mass(start = 100,min = 0,max = 100000, nominal = 100);
    type HeatFlowRate =      Modelica.SIunits.HeatFlowRate(start = 1.0e8,min = -1.0e11, max = 1.0e11, nominal = 1.0e8);
    type MassFlowRate =
                     Modelica.SIunits.MassFlowRate(min = -1000,max = 1000, nominal = 100);
    type Pressure =  Modelica.SIunits.Pressure(start = 5.0e5,min = -100e6,max = 100.0e7, nominal = 5.0e5);
    type Temperature=Modelica.SIunits.Temperature(start = 400, min = 273,max = 1500, nominal = 400);
    type Volume = Modelica.SIunits.Volume(start = 1,min = 0,max = 10000, nominal = 1);
  end Units;
    annotation (
  version=\"2.1beta\",
 preferedView=\"info\",
 uses(Modelica(version=\"3.2\")),
 conversion(from(version=\"1.8\", script=\"Scripts/ConvertSiemensPower_from_1.8_to_2.0.mos\"), from(version=\"2.0\", script=\"Scripts/ConvertSiemensPower_from_2.0_to_2.1.mos\")),
     Documentation(info=\"<html>
<blockquote>The SiemensPower <a href=\\\"http://www.modelica.org/\\\">Modelica</a> library contains models for power plant simulation.</blockquote><blockquote>Change requests can be submitted at the <a href=\\\"http://diagnostics-cvs/trac/Modelica\\\">SiemensPower trac</a> site. </blockquote>
<p><b><font style=\\\"font-size: 10pt; \\\">Articles</font></b></p>
<p><ul>
<li>For the user: Frequently asked questions regarding Dymola, Modelica and SiemensPower: <a href=\\\"http://diagnostics-cvs/trac/Modelica/wiki/Dymola/DymolaFAQ\\\">FAQ</a> </li>
<li>For the model developer: <a href=\\\"http://diagnostics-cvs/trac/Modelica/wiki/SiemensPower/ModelingGuidelines\\\">Guidelines</a> </li>
</ul></p>
<p><b><font style=\\\"font-size: 10pt; \\\">Contact</font></b> </p>
<blockquote><a href=\\\"mailto:Kilian.Link@siemens.com\\\">Kilian Link</a></blockquote><blockquote>Siemens AG</blockquote><blockquote>Energy Sector </blockquote><blockquote>E F ES EN 12 </blockquote><blockquote>P.O. Box 3220 </blockquote><blockquote>91050 Erlangen </blockquote><blockquote>Germany </blockquote>
<p><b><font style=\\\"font-size: 10pt; \\\">Copyright and Disclaimer</font></b> </p>
<blockquote><br/>Copyright  2007-2010 Siemens AG, E F ES EN 12. All rights reserved.</blockquote><blockquote><br/>The library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\\\"../Documents/Disclaimer.html\\\">disclaimer</a>. </blockquote>
</html>\",
revisions=\"<html>
<p>See <a href=\\\"http://diagnostics-cvs/trac/Modelica/roadmap\\\">roadmap</a> for future developments. </p>
<p><ul>
<li>August 2011, SiemensPower 2.0 based on Modelica 3.2  </li>
<li>May 2011, SiemensPower 1.8 based on Modelica 3.2  </li>
<li>Dec 2010, SiemensPower 1.7 based on Modelica 3.1 (including Modelica.Fluid) </li>
<li>June 2010, SiemensPower 1.6 based on Modelica 3.1 (including Modelica.Fluid) </li>
<li>April 2009, SiemensPower 1.4 based on Modelica.Fluid 1.0 (stream connector) </li>
<li>Feb 2009, SiemensPower 1.1 based on MSL 3.0 </li>
<li>Oct 2008, SiemensPower 1.0 based on Modelica.Fluid 1.0 Beta 2 </li>
</ul></p>
</html>\"));
end SiemensPower;
"));
end SiemensPower;
