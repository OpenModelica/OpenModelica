model SteamPipe
  "Detailed thermal advection model with thermal expansion effects using IF97 water vapour"
  import SI = Modelica.SIunits;
  replaceable package Medium = Modelica.Media.Water.StandardWater
    constrainedby Modelica.Media.Interfaces.PartialMedium;
  parameter Integer N = 10 "Number of nodes";
  parameter SI.Volume Vtot = 1 "Total volume";
  parameter Real w_nom = 2 "Nominal mass flow rate";
  parameter Real dp_nom = 1e5
    "Nominal total pressure loss at full flow rate";
  parameter Real p_nom = 10e5 "Nominal pressure at outlet";
  parameter Real h_nom = 3.1e6 "Nominal specific enthalpy";
  parameter SI.Pressure p_start = p_nom "Initial value of pressure states";
  parameter SI.SpecificEnthalpy h_start = h_nom
    "Initial value of enthalpy states";
  final parameter Real kf = w_nom / (dp_nom/N) "Friction coefficient";
  final parameter SI.Volume V=Vtot/N "Total volume";
  final parameter SI.Density rho_av = Medium.density_ph(p_nom+dp_nom/2, h_nom)
    "Average density";
  final parameter SI.Time tau = Vtot*rho_av/w_nom
    "Estimated transport delay at nominal conditions";
  SI.MassFlowRate w_in_pipe = 0 + (if time>1 then w_nom else 0)
    "Inlet mass flow rate";
  SI.SpecificEnthalpy h_in_pipe = h_nom + (if time > 10 then 5000 else 0)
    "Inlet specific enthalpy";

  SI.Mass M[N] "Fluid mass within each volume";
  SI.Energy E[N] "Fluid internal energy within each volume";
  SI.MassFlowRate w_in[N] "Inlet flow rate of each volume";
  SI.MassFlowRate w_out[N] "Outlet flow rate of each volume";
  SI.Pressure p[N](each stateSelect=StateSelect.prefer,
                   each start = p_start, each fixed = true)
    "Pressure states";
  SI.SpecificEnthalpy h[N](each stateSelect=StateSelect.prefer,
                           each start = h_start, each fixed = true)
    "Specific enthalpy states";
  SI.SpecificEnthalpy h_in[N] "Inlet specific enthalpy of each volume";
  SI.SpecificEnthalpy h_out[N] "Outlet specific enthalpy of each volume";
  SI.Density rho[N] "Volume density";
  Medium.ThermodynamicState state[N] "Volume thermodynamic state";
  SI.Pressure p_in_pipe "Inlet pressure";
  SI.Pressure p_out_pipe "Outlet pressure";
  SI.MassFlowRate w_out_pipe "Inlet flow rate";
  SI.SpecificEnthalpy h_out_pipe " Outlet flow rate";
equation
  for i in 1:N loop
    M[i]= V*rho[i];
    E[i]=M[i]*h[i]-p[i]*V;
    der(M[i]) = w_in[i] - w_out[i];
    der(E[i]) = w_in[i]*h_in[i]-w_out[i]*h_out[i];
    state[i]=Medium.setState_ph(p[i],h[i]);
    rho[i]=Medium.density(state[i]);
    h_out[i] = h[i];
  end for;
  for i in 1:N-1 loop
    w_out[i]=w_in[i+1];
    w_out[i]= kf*(p[i]-p[i+1]);
    h_in[i+1] = h_out[i];
  end for;
  w_out[N] = kf*(p[N]-p_nom);
  p_in_pipe = p[1];
  p_out_pipe = p[N];
  w_in_pipe = w_in[1];
  w_out_pipe = w_out[N];
  h_in_pipe = h_in[1];
  h_out_pipe = h[N];

  annotation (Documentation(info="<html>
<p>This models shows the mass, energy, and momentum balance equations for 1D flow of steam in a pipe, using the finite volume method. The pressure loss is assumed to be linear with the flow rate for simplicity. The inertial term and the kinetic term are neglected in the momentum balance equations, hence the pressure wave dynamics is not represented. The pipe is adiabatic, with zero energy storage in the walls. The industry-standard IF97 model is used to compute the steam properties.</p>
<p>The boundary conditions at the inlet are prescribed mass flow w_in_pipe and specific enthalpy h_in_pipe. The boundary condition at the outlet is constant pressure. At time = 0 the inlet flow is zero; at time = 1 the inlet flow is changed to 2 kg/s and at time = 10 the inlet specific enthalpy is raised by 5000 J/kg.</p>
</html>"));
end SteamPipe;
