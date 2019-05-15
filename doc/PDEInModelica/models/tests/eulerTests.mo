package eulerTests
  model Euler
    constant Integer N = 800;
    parameter Real L = 1;
    parameter Real dx = L / (N - 1);
    parameter Real dt;
    parameter Real[N] x = array(i * dx for i in 0:N - 1);
    Real[N] rho, v, p, E;
    Real[N] rho_x, v_x, p_x, E_x;
    parameter Real gamma = 1.4, x_0, T;
    parameter Real rho_l, v_l, p_l;
    parameter Real rho_r, v_r, p_r;
  initial equation
    rho = array(if x[i] < x_0 then rho_l else rho_r for i in 1:N);
    v = array(if x[i] < x_0 then v_l else v_r for i in 1:N);
    p = array(if x[i] < x_0 then p_l else p_r for i in 1:N);
  equation
    //BCs (probably they should be only 4):
    rho_x[1] = 0;
    rho_x[N] = 0;
    v_x[1] = 0;
    v_x[N] = 0;
    p_x[1] = 0;
    p_x[N] = 0;
    E_x[1] = 0;
    E_x[N] = 0;
    for i in 2:N - 1 loop
      //discretization of spatial derivative:
      rho_x[i] = (rho[i + 1] - rho[i - 1]) / (2 * dx);
      v_x[i] = (v[i + 1] - v[i - 1]) / (2 * dx);
      p_x[i] = (p[i + 1] - p[i - 1]) / (2 * dx);
      E_x[i] = (E[i + 1] - E[i - 1]) / (2 * dx);
    end for;
    // the equation:
    der(rho) = (-rho_x .* v) - rho .* v_x;
    der(rho .* v) = (-rho_x .* v .^ 2) - rho .* v .* v_x - p_x;
    der(E) = (-v_x .* (E + p)) - v .* (E_x + p_x);
    //-v_x .* (E + p) - v .* (E_x + p_x);
    E = p / (gamma - 1) + rho .* v .^ 2 / 2.0;
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1e-08, Interval = 0.001));
  end Euler;

  model EulerViscosity
    constant Integer N = 100;
    parameter Real L = 1;
    parameter Real dx = L / (N - 1);
    parameter Real[N] x = array(i * dx for i in 0:N - 1);
    Real[N] rho, v, p, eps, q, vs;
    Real[N] rho_x, v_x, p_x, q_x;
    parameter Real gamma = 1.4, x_0, T;
    parameter Real rho_l, v_l, p_l;
    parameter Real rho_r, v_r, p_r;
  initial equation
    rho = array(if x[i] < x_0 then rho_l else rho_r for i in 1:N);
    v = array(if x[i] < x_0 then v_l else v_r for i in 1:N);
    p = array(if x[i] < x_0 then p_l else p_r for i in 1:N);
  equation
    //BCs (probably they should be only 4):
    rho_x[1] = 0;
    rho_x[N] = 0;
    v_x[1] = 0;
    v_x[N] = 0;
    p_x[1] = 0;
    p_x[N] = 0;
    q_x[1] = 0;
    q_x[N] = 0;
    for i in 2:N - 1 loop
      //discretization of spatial derivative:
      rho_x[i] = (rho[i + 1] - rho[i - 1]) / (2 * dx);
      v_x[i] = (v[i + 1] - v[i - 1]) / (2 * dx);
      p_x[i] = (p[i + 1] - p[i - 1]) / (2 * dx);
      q_x[i] = (q[i + 1] - q[i - 1]) / (2 * dx);
    end for;
    // the equation:
    der(rho) = (-rho_x .* v) - rho .* v_x;
    der(rho .* v) = (-rho_x .* v .^ 2) - rho .* v .* v_x - p_x - q_x;
    rho .* der(eps) = -(p + q) .* v_x;
    p = eps .* rho .* (gamma - 1);
    vs = sqrt((gamma - 1) * gamma * eps);
    for i in 1:N loop
      q[i] = if v_x[i] < 0 then -3 / 2 * rho[i] * v_x[i] * dx * vs[i] else 0;
    end for;
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 4e-05));
  end EulerViscosity;

  model Riemann1
    extends Euler(rho_l = 1, v_l = 0.75, p_l = 1, rho_r = 0.125, v_r = 0, p_r = 0.1, x_0 = 0.3);
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 0.001));
  end Riemann1;

  model Riemann1V
    EulerViscosity riemann1(rho_l = 1, v_l = 0.75, p_l = 1, rho_r = 0.125, v_r = 0, p_r = 0.1, x_0 = 0.3);
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 0.0004));
  end Riemann1V;
end eulerTests;