package HeatTransfer1D_TestCase "1D Heat transfer test case for array preserving and limited code size by model rewriting"
  model InsulatedRod_equations
    "Standard implementaton of an insulated rod with equations"
    import Modelica.Units.SI;
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a annotation (Placement(
          transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b annotation (Placement(
          transformation(extent={{90,-10},{110,10}}, rotation=0)));
    parameter SI.Length L=1 "lenght of rod";
    parameter SI.Area A=0.0004 "area of rod";
    parameter SI.Density rho=7500 "density of rod material";
    parameter SI.ThermalConductivity lambda=74 "thermal conductivity of material";
    parameter SI.SpecificHeatCapacity c=450 "specifc heat capacity";
    parameter SI.Temperature T0=293.15 "initial temperature";
    parameter Integer nT(min=1)=2 "number of inner nodes" annotation(__OpenModelica_resizable=true);
    SI.Temperature  T[nT](each start=T0, each fixed=true) "temperatures at inner nodes";
    SI.HeatFlowRate Q_flow[nT+1];
  protected
    parameter Real dx = L/nT;
    parameter Real k1 = lambda*A/dx;
    parameter Real k2 = rho*c*A*dx;

  equation
    port_a.Q_flow = 2*k1*(port_a.T - T[1]);
    port_b.Q_flow = 2*k1*(T[nT] - port_b.T);

    Q_flow[1] =port_a.Q_flow;
    for i in 2:nT loop
      Q_flow[i] = k1*(T[i-1] - T[i]);
    end for;
    Q_flow[nT+1] =-port_b.Q_flow;

    for i in 1:nT loop
      der(T[i]) =(Q_flow[i] - Q_flow[i + 1])/k2;
    end for;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(
            extent={{-90,18},{90,-22}},
            lineColor={0,0,0},
            fillPattern=FillPattern.HorizontalCylinder,
            fillColor={191,0,0}),
          Text(extent={{-150,84},{140,38}},
            textColor={0,0,255},
            textString="%name"),
          Line(points={{-60,18},{-60,-20}}, color={0,0,0}),
          Line(points={{20,18},{20,-20}}, color={0,0,0}),
          Line(points={{60,16},{60,-22}}, color={0,0,0}),
          Line(points={{-20,16},{-20,-22}}, color={0,0,0}),
          Text(
            extent={{-136,-38},{124,-78}},
            lineColor={0,0,0},
            textString="nT=%nT"),
          Text(
            extent={{-66,14},{56,-16}},
            textColor={255,255,255},
            textString="equ")}),                                   Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end InsulatedRod_equations;

  model InsulatedRod_algorithm "Insulated rod with algorithm section for inner nodes"
    import Modelica.Units.SI;
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a annotation (Placement(
          transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b annotation (Placement(
          transformation(extent={{90,-10},{110,10}}, rotation=0)));
    parameter SI.Length L=1 "lenght of rod";
    parameter SI.Area A=0.0004 "area of rod";
    parameter SI.Density rho=7500 "density of rod material";
    parameter SI.ThermalConductivity lambda=74 "thermal conductivity of material";
    parameter SI.SpecificHeatCapacity c=450 "specifc heat capacity";
    parameter SI.Temperature T0=293.15 "initial temperature";
    parameter Integer nT(min=1)=2 "number of inner nodes";
    SI.Temperature  T[nT](each start=T0, each fixed=true) "temperatures at inner nodes";
    SI.HeatFlowRate Q_flow[nT+1];
  protected
    parameter Real dx = L/nT;
    parameter Real k1 = lambda*A/dx;
    parameter Real k2 = rho*c*A*dx;

  equation
    // Acausal part
    port_a.Q_flow = 2*k1*(port_a.T - T[1]);
    port_b.Q_flow = 2*k1*(T[nT] - port_b.T);

  algorithm
    // Causal part
    Q_flow[1] :=port_a.Q_flow;
    for i in 2:nT loop
      Q_flow[i] := k1*(T[i-1] - T[i]);
    end for;
    Q_flow[nT+1] :=-port_b.Q_flow;

    for i in 1:nT loop
      der(T[i]) :=(Q_flow[i] - Q_flow[i + 1])/k2;
    end for;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(
            extent={{-90,18},{90,-22}},
            lineColor={0,0,0},
            fillPattern=FillPattern.HorizontalCylinder,
            fillColor={191,0,0}),
          Text(extent={{-150,84},{140,38}},
            textColor={0,0,255},
            textString="%name"),
          Line(points={{-60,18},{-60,-20}}, color={0,0,0}),
          Line(points={{20,18},{20,-20}}, color={0,0,0}),
          Line(points={{60,16},{60,-22}}, color={0,0,0}),
          Line(points={{-20,16},{-20,-22}}, color={0,0,0}),
          Text(
            extent={{-136,-38},{124,-78}},
            lineColor={0,0,0},
            textString="nT=%nT"),
          Text(
            extent={{-66,14},{56,-16}},
            textColor={255,255,255},
            textString="alg")}),                                   Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end InsulatedRod_algorithm;

  model InsulatedRod_function "Insulated rod with function for inner nodes"
    import Modelica.Units.SI;
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a annotation (Placement(
          transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b annotation (Placement(
          transformation(extent={{90,-10},{110,10}}, rotation=0)));
    parameter SI.Length L=1 "lenght of rod";
    parameter SI.Area A=0.0004 "area of rod";
    parameter SI.Density rho=7500 "density of rod material";
    parameter SI.ThermalConductivity lambda=74 "thermal conductivity of material";
    parameter SI.SpecificHeatCapacity c=450 "specifc heat capacity";
    parameter SI.Temperature T0=293.15 "initial temperature";
    parameter Integer nT(min=1) "number of inner nodes";
    SI.Temperature  T[nT](each start=T0, each fixed=true) "temperatures at inner nodes";
  protected
    parameter Real dx = L/nT;
    parameter Real k1 = lambda*A/dx;
    parameter Real k2 = rho*c*A*dx;

    function innerInsulatedRod "Causal part"
      input SI.Temperature T[:];
      input Real k1;
      input Real k2;
      input SI.HeatFlowRate Q_flow_a;
      input SI.HeatFlowRate Q_flow_b;
      output Real der_T[size(T,1)];
    protected
      Integer nT = size(T,1);
      SI.HeatFlowRate Q_flow[nT+1];
    algorithm
      Q_flow[1] := Q_flow_a;
      for i in 2:nT loop
        Q_flow[i] := k1*(T[i-1] - T[i]);
      end for;
      Q_flow[nT+1] :=-Q_flow_b;

      for i in 1:nT loop
        der_T[i] :=(Q_flow[i] - Q_flow[i + 1])/k2;
      end for;
    end innerInsulatedRod;
  equation
    // Acausal part
    port_a.Q_flow = 2*k1*(port_a.T - T[1]);
    port_b.Q_flow = 2*k1*(T[nT] - port_b.T);

    // Causal part
    der(T) = innerInsulatedRod(T, k1, k2, port_a.Q_flow, port_b.Q_flow);
    annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(
            extent={{-90,18},{90,-22}},
            lineColor={0,0,0},
            fillPattern=FillPattern.HorizontalCylinder,
            fillColor={191,0,0}),
          Text(extent={{-150,84},{140,38}},
            textColor={0,0,255},
            textString="%name"),
          Line(points={{-60,18},{-60,-20}}, color={0,0,0}),
          Line(points={{20,18},{20,-20}}, color={0,0,0}),
          Line(points={{60,16},{60,-22}}, color={0,0,0}),
          Line(points={{-20,16},{-20,-22}}, color={0,0,0}),
          Text(
            extent={{-136,-38},{124,-78}},
            lineColor={0,0,0},
            textString="nT=%nT"),
          Text(
            extent={{-56,12},{52,-14}},
            textColor={255,255,255},
            textString="func")}),                                  Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end InsulatedRod_function;

  model Test1_equations
    "Test case with equations and different connection causalities"
    extends Modelica.Icons.Example;

    Modelica.Thermal.HeatTransfer.Celsius.FixedTemperature Tsource(T=200)
      annotation (Placement(transformation(extent={{-80,0},{-60,20}},  rotation=
             0)));
    InsulatedRod_equations
                  insulatedRod(T0=323.15, nT=10)
      annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
    Modelica.Thermal.HeatTransfer.Sources.FixedHeatFlow fixedHeatFlow2(Q_flow=5)
      annotation (Placement(transformation(extent={{20,0},{0,20}})));
  equation
    connect(Tsource.port, insulatedRod.port_a)
      annotation (Line(points={{-60,10},{-40,10}}, color={191,0,0}));
    connect(insulatedRod.port_b, fixedHeatFlow2.port)
      annotation (Line(points={{-20,10},{0,10}}, color={191,0,0}));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)),
      experiment(StopTime=100000, __Dymola_Algorithm="Dassl"));
  end Test1_equations;

  model Test1_algorithm "Test case with algorithm section and different connection causalities"
    extends Modelica.Icons.Example;

    Modelica.Thermal.HeatTransfer.Celsius.FixedTemperature Tsource(T=200)
      annotation (Placement(transformation(extent={{-80,0},{-60,20}},  rotation=
             0)));
    InsulatedRod_algorithm
                  insulatedRod(T0=323.15, nT=10)
      annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
    Modelica.Thermal.HeatTransfer.Sources.FixedHeatFlow fixedHeatFlow2(Q_flow=5)
      annotation (Placement(transformation(extent={{20,0},{0,20}})));
  equation
    connect(Tsource.port, insulatedRod.port_a)
      annotation (Line(points={{-60,10},{-40,10}}, color={191,0,0}));
    connect(insulatedRod.port_b, fixedHeatFlow2.port)
      annotation (Line(points={{-20,10},{0,10}}, color={191,0,0}));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)),
      experiment(StopTime=100000, __Dymola_Algorithm="Dassl"));
  end Test1_algorithm;

  model Test1_function "Test case with a function and different connection causalities"
    extends Modelica.Icons.Example;

    Modelica.Thermal.HeatTransfer.Celsius.FixedTemperature Tsource(T=200)
      annotation (Placement(transformation(extent={{-80,0},{-60,20}},  rotation=
             0)));
    InsulatedRod_function insulatedRod(nT=10)
      annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
    Modelica.Thermal.HeatTransfer.Sources.FixedHeatFlow fixedHeatFlow2(Q_flow=5)
      annotation (Placement(transformation(extent={{22,0},{2,20}})));
  equation
    connect(insulatedRod.port_a, Tsource.port)
      annotation (Line(points={{-40,10},{-60,10}}, color={191,0,0}));
    connect(insulatedRod.port_b, fixedHeatFlow2.port)
      annotation (Line(points={{-20,10},{2,10}}, color={191,0,0}));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)),
      experiment(StopTime=100000, __Dymola_Algorithm="Dassl"));
  end Test1_function;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    uses(Modelica(version="4.0.0")),
    Documentation(info="<html>

<p>
This test case models 1D heat transfer in a totally isolated rod.
The number of internal nodes shall be configurable.
The goals is that this number can be changed before simulation starts, without re-compilation.
Also the code-size should be minimal: If many InsulatedRod models are used, the code
for the model should be present only once in the compiled system.
This is the case for \"InsulatedRod_function\".
</p>


<p>
<em>
This Modelica package is <u>free</u> software and
the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the
3-Clause BSD license<br>
<b>Copyright &copy; 2023, DLR Institute of System Dynamics and Control(SR) </b>
</p>


</html>", revisions="<html>
<p><i>Nov. 23, 2023 by Martin Otter (DLR-SR):</i> Initial version</p>
</html>"));
end HeatTransfer1D_TestCase;
