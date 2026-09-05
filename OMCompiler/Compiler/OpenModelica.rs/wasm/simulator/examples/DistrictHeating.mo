model DistrictHeating
  "District heating grid: N*N buildings on a turbulent pipe network"

  parameter Integer N = 12 "Grid side, so the plant feeds N*N buildings";

  // Hydraulic network
  parameter Real R(unit = "Pa.s2/kg2") = 1e5
    "Flow resistance of one pipe segment";
  // kg/(s.Pa^0.5): Modelica's unit syntax has no half-integer exponent.
  parameter Real Kv = 6e-4 "Radiator valve coefficient wide open";
  parameter Real pSupply(unit = "Pa") = 6e5 "Plant supply pressure";
  parameter Real pReturn(unit = "Pa") = 1e5 "Return line pressure";
  parameter Real dpReg(unit = "Pa") = 100
    "Regularisation of the turbulent flow law";

  // Buildings
  parameter Real cp(unit = "J/(kg.K)") = 4180 "Specific heat of water";
  parameter Real C(unit = "J/K") = 4e6 "Thermal mass of one building";
  parameter Real UA(unit = "W/K") = 400 "Envelope conductance";
  parameter Real Tsupply(unit = "K", displayUnit = "degC") = 350
    "Supply water temperature";
  parameter Real Tambient(unit = "K", displayUnit = "degC") = 273.15
    "Outdoor temperature";
  parameter Real Tset(unit = "K", displayUnit = "degC") = 293.15
    "Thermostat set point";
  parameter Real gain(unit = "1/K") = 2 "Thermostat gain";
  parameter Real Qocc(unit = "W") = 1200 "Peak occupancy heat gain";
  parameter Real Tocc(unit = "s") = 3600 "Period of the occupancy cycle";

  Real p[N, N](each unit = "Pa", each start = 3e5, each nominal = 1e5)
    "Pressure at each network node";
  Real qh[N, N - 1](each unit = "kg/s", each start = 0.5, each nominal = 1)
    "Flow through the pipes running east";
  Real qv[N - 1, N](each unit = "kg/s", each start = 0.5, each nominal = 1)
    "Flow through the pipes running south";
  Real qDraw[N, N](each unit = "kg/s", each nominal = 0.2)
    "Flow drawn by each building";
  Real valve[N, N](each nominal = 6e-4) "Radiator valve coefficient";
  Real T[N, N](each unit = "K", each displayUnit = "degC", each start = 288.15,
    each fixed = true, each nominal = 300)
    "Indoor temperature of each building";

  Real Tnear(unit = "K", displayUnit = "degC") = T[1, 1]
    "Indoor temperature next to the plant";
  Real Tfar(unit = "K", displayUnit = "degC") = T[N, N]
    "Indoor temperature at the far corner";
  Real Tmean(unit = "K", displayUnit = "degC") = sum(T)/N^2
    "Average indoor temperature";
  Real pFar(unit = "Pa") = p[N, N] "Pressure at the far corner";
  Real qNear(unit = "kg/s") = qDraw[1, 1] "Water drawn next to the plant";
  Real qFar(unit = "kg/s") = qDraw[N, N] "Water drawn at the far corner";
  Real qPlant(unit = "kg/s") = qh[1, 1] + qv[1, 1] + qDraw[1, 1]
    "Flow leaving the plant";

  function turbulent "Regularised turbulent flow law, solved for the flow"
    input Real dp(unit = "Pa") "Pressure drop";
    input Real R(unit = "Pa.s2/kg2") "Resistance";
    input Real dpReg(unit = "Pa") "Regularisation";
    output Real q(unit = "kg/s") "Mass flow";
  algorithm
    q := dp/sqrt(R*sqrt(dp^2 + dpReg^2));
  end turbulent;

equation
  for i in 1:N, j in 1:N - 1 loop
    qh[i, j] = turbulent(p[i, j] - p[i, j + 1], R, dpReg);
  end for;
  for i in 1:N - 1, j in 1:N loop
    qv[i, j] = turbulent(p[i, j] - p[i + 1, j], R, dpReg);
  end for;

  p[1, 1] = pSupply;

  for i in 1:N, j in 1:N loop
    valve[i, j] = Kv*0.5*(1 + tanh(gain*(Tset - T[i, j])));
    qDraw[i, j] = valve[i, j]*(p[i, j] - pReturn)/((p[i, j] - pReturn)^2 + dpReg^2)^0.25;
    C*der(T[i, j]) = cp*qDraw[i, j]*(Tsupply - T[i, j]) - UA*(T[i, j] - Tambient)
                     + Qocc*(1 + sin(2*3.14159265358979*time/Tocc + 0.7*(i + 3*j)));
  end for;

  // Mass balance at every node but the plant, which supplies whatever is drawn.
  for i in 1:N, j in 1:N loop
    if i <> 1 or j <> 1 then
      (if j > 1 then qh[i, j - 1] else 0) - (if j < N then qh[i, j] else 0)
      + (if i > 1 then qv[i - 1, j] else 0) - (if i < N then qv[i, j] else 0) = qDraw[i, j];
    end if;
  end for;

annotation(
  experiment(StopTime = 10800, Tolerance = 1e-6),
  Documentation(
    info = "<html>
<p>A heat plant feeds <b>N&times;N</b> buildings through a grid of pipes. Every
building has a thermal mass, an envelope losing heat to the outdoors, an
occupancy heat gain on its own phase, and a thermostatic radiator valve. The
pipes are turbulent, so the flow through one is a regularised square root of the
pressure drop across it.</p>

<p>That makes the <b>N&times;N</b> node pressures, the pipe flows and the
building draws one large nonlinear algebraic system, coupled to one state per
building.</p>

<h4>Why DAE mode wins here</h4>

<p>Solving the network for the derivatives, as ODE mode must, couples
<i>every</i> building to every other one: eliminating the pressures makes the
Jacobian of the resulting ODE dense, and DASSL builds it one column per state,
each column paying for a full solve of the network. DAE mode hands the residuals
to IDA unsolved, so the Jacobian keeps the sparsity of the grid — a building
only ever touches its four neighbours — and a coloured sparse Jacobian costs a
handful of residual evaluations however large the grid is.</p>

<h4>Why DAE mode does not always win</h4>

<p>The residual form hands the integrator <i>more</i> unknowns, not fewer: IDA advances
the pressures and flows alongside the temperatures, so its error test and its Newton
iteration cover variables that ODE mode keeps inside the model's own equation
evaluation. That is the price, and it is why DAE mode takes more steps here.</p>

<p>It is worth paying only when eliminating those unknowns is what makes the ODE
Jacobian expensive, as the shared network makes it here. A model whose algebraic loops
stay local &mdash; a few small torn systems, each touching a handful of variables &mdash;
already has a cheap, sparse state Jacobian, so DAE mode integrates the larger system and
gets nothing back for it. Many models are of that kind, and for them the box is better
left clear.</p>

<p>Setting it also fixes the integrator, since only IDA steps a residual form: a model
that a cheaper method handles well gives up that choice.</p>

<h4>Try it</h4>

<p>Open <b>Settings</b> and clear the <b>DAE mode</b> checkbox, which is on for
this example. The model is translated again for the ODE backend and the run takes
several times longer; the status line reports the build and simulation times, and
the step, ODE and Jacobian counts, for both. At the default grid of 144 buildings
the simulation is around four times slower in ODE mode in a browser, the
translation about a third slower, and both gaps widen with <code>N</code> — the
ODE Jacobian's cost grows with the square of the number of buildings, the
residual one linearly.</p>

<p>The step counts tell the same story from the other side: DAE mode takes
<i>more</i> steps, because IDA's error test covers the algebraic unknowns too, and
still finishes sooner — each step is that much cheaper.</p>

<p>Turning DAE mode on also makes IDA the integrator — the residual form has no
explicit derivatives for another solver to step — so the integration method is
fixed while the checkbox is set. Exporting an FMU with the box set exports the
DAE form too: Co-Simulation embeds IDA over the residuals, and Model Exchange
adds the <code>fmi-ls-dae</code> layered standard beside the ordinary ODE
interface.</p>
</html>",
    figures = {
      Figure(
        title = "Indoor temperatures",
        identifier = "temperatures",
        plots = {Plot(curves = {
          Curve(y = Tnear, legend = "next to the plant"),
          Curve(y = Tfar, legend = "far corner"),
          Curve(y = Tmean, legend = "grid average")})},
        caption = "Every building starts cold and is pulled towards the 20 °C
set point. The occupancy gains run on a different phase in each building, so the
valves never settle and the network keeps being re-solved."),
      Figure(
        title = "Hydraulics",
        identifier = "hydraulics",
        plots = {
          Plot(title = "Flow leaving the plant", curves = {Curve(y = qPlant)}),
          Plot(title = "Water reaching a building", curves = {
            Curve(y = qNear, legend = "next to the plant"),
            Curve(y = qFar, legend = "far corner")}),
          Plot(title = "Pressure at the far corner", curves = {Curve(y = pFar)})},
        caption = "The plant flow follows the aggregated valve openings. The far
corner sits at barely more than the return pressure, so however wide its valve
opens it draws a fraction of what the buildings near the plant get - which is
why it never reaches the set point.")}));
end DistrictHeating;
