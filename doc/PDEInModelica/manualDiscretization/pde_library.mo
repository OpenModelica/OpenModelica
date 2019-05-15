package pde_experiments
  model der_x
    parameter Real[N - 2] u_0;
    parameter Integer N = 10;
    parameter Real dx = 0.1;
    Modelica.Blocks.Interfaces.RealInput u[N] annotation(Placement(transformation(extent = {{-100,-20},{-60,20}}), iconTransformation(extent = {{-100,-20},{-60,20}})));
    Modelica.Blocks.Interfaces.RealOutput u_x[N] annotation(Placement(transformation(extent = {{80,-10},{100,10}}), iconTransformation(extent = {{80,-10},{100,10}})));
  initial equation
    u[2:N - 1] = u_0;
  equation
    u[1] = u[2];
    for i in 2:N - 1 loop
    u_x[i] = (u[i + 1] - u[i - 1]) / (2 * dx);

    end for;
    u[N - 1] = u[N];
    annotation(Icon(graphics));
  end der_x;
  model HeatEq
    parameter Real q = 1.0;
    constant Integer N = 10;
    der_xx der_xx1(u_0 = array(if i <= N / 2 then 1 else 0 for i in 2:N - 1), N = N) annotation(Placement(transformation(extent = {{-20,22},{0,42}})));
  equation
    der(der_xx1.u) = q * der_xx1.u_xx;
  end HeatEq;
  partial model der_xx
    parameter Real[N - 2] u_0;
    parameter Integer N = 10;
    parameter Real dx = 1.0;
    Modelica.Blocks.Interfaces.RealInput u[N] annotation(Placement(transformation(extent = {{-100,-20},{-60,20}}), iconTransformation(extent = {{-100,-20},{-60,20}})));
    Modelica.Blocks.Interfaces.RealOutput u_xx[N] annotation(Placement(transformation(extent = {{80,-10},{100,10}}), iconTransformation(extent = {{80,-10},{100,10}})));
  initial equation
    u[2:N - 1] = u_0;
  equation
    u[1] = u[2];
    for i in 2:N - 1 loop
    u_xx[i] = (u[i + 1] - 2 * u[i] + u[i - 1]) / dx ^ 2;

    end for;
    u[N - 1] = u[N];
    annotation(Icon(graphics));
  end der_xx;
  model eqTests
    parameter Real q = 1;
    parameter Real L = 20;
    //  constant Integer N = 10;
    replaceable package x = PDESpatialVar;
    PDEField u(redeclare package x = x, u_0 = array(if i <= x.N / 2 then 1 else 0 for i in 2:x.N - 1)) annotation(Placement(transformation(extent = {{-20,22},{0,42}})));
  equation
    der(u.u) = q * u.u_xx;
  end eqTests;
  package PDESpatialVar
    constant Integer N = 10;
    constant Real L = 1;
    constant Real dx = L / (N - 1);
    constant Real x[N] = array(dx * i for i in 1:N);
    annotation(Icon(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})), Diagram(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})));
  end PDESpatialVar;
  block PDEField
    replaceable package x = PDESpatialVar;
    constant Real[x.N - 2] u_0;
    constant Real dx = x.L / (x.N - 1);
    constant Integer N = x.N;
    Modelica.Blocks.Interfaces.RealInput u[x.N] annotation(Placement(transformation(extent = {{-100,-20},{-60,20}}), iconTransformation(extent = {{-100,-20},{-60,20}})));
    Modelica.Blocks.Interfaces.RealOutput u_x[N] annotation(Placement(visible = true, transformation(origin = {87.7114,37.8805}, extent = {{-12,-12},{12,12}}, rotation = 0), iconTransformation(origin = {87.7114,37.8805}, extent = {{-12,-12},{12,12}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput u_xx[N] annotation(Placement(visible = true, transformation(origin = {90.451,-41.0372}, extent = {{-10,-10},{10,10}}, rotation = 0), iconTransformation(origin = {90.451,-41.0372}, extent = {{-10,-10},{10,10}}, rotation = 0)));
  initial equation
    u[2:N - 1] = u_0;
  equation
    u[1] = u[2];
    //  u_xx[1] = (u[3] - 2 * u[2] + u[1]) / dx ^ 2;
    u_x[1] = (-3 / 2 * u[1] + 2 * u[2] - 1 / 2 * u[3]) / dx;
    for i in 2:N - 1 loop
    u_xx[i] = (u[i + 1] - 2 * u[i] + u[i - 1]) / dx ^ 2;
    u_x[i] = (u[i + 1] - u[i - 1]) / (2 * dx);

    end for;
    u[N - 1] = u[N];
    //  u_xx[N] = (u[N] - 2 * u[N - 1] + u[N - 2]) / dx ^ 2;
    u_x[N] = (3 / 2 * u[N] - 2 * u[N - 1] + 1 / 2 * u[N - 2]) / dx;
    annotation(Diagram, Icon(graphics = {Text(rotation = 0, lineColor = {0,0,255}, fillColor = {0,0,0}, pattern = LinePattern.Solid, fillPattern = FillPattern.None, lineThickness = 0.25, extent = {{-61.7813,78.9177},{61.3303,-78.0158}}, textString = "PDE", fontName = "MS Serif")}), Icon(graphics));
  end PDEField;
  model arterialPulsWave
    annotation(Icon(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})), Diagram(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})));
  end arterialPulsWave;
  annotation(uses(Modelica(version = "3.2")));
end pde_experiments;

