within ;
model AlgorithmSize
  block conditionSignal
    Modelica.Blocks.Interfaces.RealInput u
      annotation (Placement(transformation(extent={{-124,-20},{-84,20}})));
    Modelica.Blocks.Interfaces.RealOutput y
      annotation (Placement(transformation(extent={{94,-20},{130,20}})));
    Real norm_u;
    parameter Real range = 1023;
    parameter Real minSignal = 0.2;
    parameter Real a = 1/(1-minSignal);
    parameter Real b = minSignal*a;
  algorithm
    norm_u := (u-range/2)/range*2;
    if norm_u < -minSignal then
      y := -a*abs(norm_u)+b;
    elseif norm_u > minSignal then
      y := a*abs(norm_u)-b;
    else
      y :=0.0;
    end if;
  end conditionSignal;

  Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape shape1(
    length=1,
    width=1,
    height=1,
    color={170,255,85},
    r={signal1.y,1,0})
    annotation (Placement(transformation(extent={{-60,40},{-40,60}})));
  conditionSignal signal1
    annotation (Placement(transformation(extent={{-100,46},{-80,66}})));
  Modelica.Blocks.Sources.Sine sine
    annotation (Placement(transformation(extent={{-128,46},{-108,66}})));
equation

  connect(signal1.u, sine.y) annotation (Line(
      points={{-100.4,56},{-107,56}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-200,
            -100},{100,100}}), graphics),
    experiment(
      StopTime=15,
      Tolerance=0.001,
      __Dymola_fixedstepsize=0.001,
      __Dymola_Algorithm="Euler"),
    __Dymola_experimentSetupOutput,
    Icon(coordinateSystem(extent={{-200,-100},{100,100}})),
    uses(Modelica(version="3.2.1")));
end AlgorithmSize;
