package InputOptIssues
  model Trapezoid "Dynamical Optimization of Ideal Drive"
    parameter Real p = 1 "required for optimization";
    parameter Real powLim = 9000;
    Real power = torque * angSpeed;
    //
    /***  Optimization requests ***/
    input Real torque(min = -90, max = 90);
    Real targetPhi(nominal = 1) = -torque2.flange.phi "minimize -pos(tf)" annotation(
      isMayer = true);
    Real angSpeed(min = 0, max = 0) = p * der(torque2.flange.phi) annotation(
      isFinalConstraint = true);
    Real pow(min = -powLim, max = powLim) = power annotation(
      isConstraint = true);
    /*** end of Optimization requests ***/
    //
    Real constPhi(nominal = 100) = -torque2.flange.phi "minimize -phi(tf)" annotation(
      isLagrange = true);
    Modelica.Blocks.Sources.RealExpression realexp(y = torque) annotation(
      Placement(visible = true, transformation(origin = {0, -34}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Components.Inertia inertia1 annotation(
      Placement(visible = true, transformation(origin = {-10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Sources.Torque torque1 annotation(
      Placement(visible = true, transformation(origin = {-48, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Sources.Trapezoid trapezoid1(amplitude = 10, falling = 1, period = 5, rising = 1, startTime = 1, width = 1) annotation(
      Placement(visible = true, transformation(origin = {58, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Sources.Torque torque2 annotation(
      Placement(visible = true, transformation(origin = {24, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
  equation
    connect(trapezoid1.y, torque2.tau) annotation(
      Line(points = {{47, 0}, {42, 0}, {42, -2}, {37, -2}}, color = {0, 0, 127}));
    connect(torque1.flange, inertia1.flange_a) annotation(
      Line(points = {{-38, 0}, {-18, 0}}));
    connect(inertia1.flange_b, torque2.flange) annotation(
      Line(points = {{2, 0}, {14, 0}}));
    connect(realexp.y, torque1.tau) annotation(
      Line(points = {{-9, -34}, {-70, -34}, {-70, 0}, {-60, 0}}, color = {0, 0, 127}));
    annotation(
      Diagram(coordinateSystem(extent = {{-80, -60}, {80, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})),
      Icon(coordinateSystem(extent = {{-80, -60}, {80, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})),
      experiment(StartTime = 0, StopTime = 8, Tolerance = 1e-07, Interval = 0.16),
      __OpenModelica_commandLineOptions = "+gDynOpt",
      __OpenModelica_simulationFlags(optimizerNP = "1", s = "optimization"));
  end Trapezoid;

  model TimeTable "Dynamical Optimization of Ideal Drive"
    parameter Real p = 1 "required for optimization";
    parameter Real powLim = 9000;
    Real power = torque * angSpeed;
    //
    /***  Optimization requests ***/
    input Real torque(min = -90, max = 90);
    Real targetPhi(nominal = 1) = -torque2.flange.phi "minimize -pos(tf)" annotation(
      isMayer = true);
    Real angSpeed(min = 0, max = 0) = p * der(torque2.flange.phi) annotation(
      isFinalConstraint = true);
    Real pow(min = -powLim, max = powLim) = power annotation(
      isConstraint = true);
    /*** end of Optimization requests ***/
    //
    Real constPhi(nominal = 100) = -torque2.flange.phi "minimize -phi(tf)" annotation(
      isLagrange = true);
    Modelica.Blocks.Sources.RealExpression realexp(y = torque) annotation(
      Placement(visible = true, transformation(origin = {0, -34}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Components.Inertia inertia1 annotation(
      Placement(visible = true, transformation(origin = {-10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Sources.Torque torque1 annotation(
      Placement(visible = true, transformation(origin = {-48, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.Rotational.Sources.Torque torque2 annotation(
      Placement(visible = true, transformation(origin = {24, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.TimeTable timeTable1(table = [
  0, 0; 1, 0;
  2,10; 3, 10;
  4, 0; 5, 0;
  6,10; 7,10;
  8,0; 9,0]
  )  annotation(
      Placement(visible = true, transformation(origin = {64, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
  equation
    connect(timeTable1.y, torque2.tau) annotation(
      Line(points = {{52, 0}, {38, 0}, {38, 0}, {36, 0}}, color = {0, 0, 127}));
    connect(torque1.flange, inertia1.flange_a) annotation(
      Line(points = {{-38, 0}, {-18, 0}}));
    connect(inertia1.flange_b, torque2.flange) annotation(
      Line(points = {{2, 0}, {14, 0}}));
    connect(realexp.y, torque1.tau) annotation(
      Line(points = {{-9, -34}, {-70, -34}, {-70, 0}, {-60, 0}}, color = {0, 0, 127}));
    annotation(
      Diagram(coordinateSystem(extent = {{-80, -60}, {80, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})),
      Icon(coordinateSystem(extent = {{-80, -60}, {80, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})),
      experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-07, Interval = 0.2),
      __OpenModelica_commandLineOptions = "+gDynOpt",
      __OpenModelica_simulationFlags(optimizerNP = "1", s = "optimization"));
  end TimeTable;



  annotation(
    Diagram(coordinateSystem(extent = {{-100, -80}, {100, 80}})),
  uses(Modelica(version = "3.2.3")));
end InputOptIssues;
