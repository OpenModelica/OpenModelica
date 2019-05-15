package conservationLaws1D
  model conservationLaw
    constant Integer M;
    constant Integer N;
    parameter Real L = 1;
    parameter Real dx = L / (N - 1);
    parameter Real[N] x = array(i * dx for i in 0:N - 1);
    Real[M, N] W, F;
    Real[M, N] F_x;
  end conservationLaw;

  model pokusy
    parameter Real[2, 3] A = {{1, 2, 3}, {4, 5, 6}};
    parameter Real As[2] = A[:, 2];
  end pokusy;

  model advection
    extends conservationLawCentral;
    Real u[N];
    parameter Real a = 1;
  initial equation
    //cos BC
    //array(if x[i] < 0.25 then cos(Modelica.Constants.pi / 2 * 4 * x[i]) else 0 for i in 1:N);
    //step BC
    //
  equation
    //dummy BCs
    F_x[1, 1] = 0;
    F_x[1, N] = 0;
    //equations
    W[1, :] = u;
    F[1, :] = a * u;
  end advection;

  model conservationLawCentral
    extends conservationLaw;
    parameter Real dt;
  equation
    for i in 2:N - 1 loop
      //discretization of spatial derivative:
      F_x[:, i] = (F[:, i + 1] - F[:, i - 1]) / (2 * dx);
      // the equation:
      der(W[:, i]) + F_x[:, i] = zeros(M);
    end for;
  end conservationLawCentral;

  model conservationLawLF
    parameter Real dt;
    parameter Real alpha = 1;
    extends conservationLaw;
  equation
    for i in 2:N - 1 loop
      //discretization of spatial derivative:
      F_x[:, i] = (F[:, i + 1] - F[:, i - 1]) / (2 * dx);
      // the equation:
      der(W[:, i]) - alpha * (W[:, i + 1] - 2 * W[:, i] + W[:, i - 1]) / (2 * dt) + F_x[:, i] = zeros(M);
      /*- (W[:, i + 1] - 2 * W[:, i] + W[:, i - 1]) / (2 * dt)*/
    end for;
  end conservationLawLF;

  model eulerEq
    extends conservationLawLF(M = 3);
    Real[N] rho, u, p, E;
    //  parameter Real u_s;
    parameter Real gamma = 1.4, x_0, T;
    parameter Real rho_l, u_l, p_l;
    parameter Real rho_r, u_r, p_r;
  initial equation
    rho = array(if x[i] < x_0 then rho_l else rho_r for i in 1:N);
    u = array(if x[i] < x_0 then u_l else u_r for i in 1:N);
    p = array(if x[i] < x_0 then p_l else p_r for i in 1:N);
  equation
    //dummy BCs
    F_x[:, 1] = zeros(M);
    F_x[:, N] = zeros(M);
    //BCs
    rho[1] = rho_l;
    u[1] = u_l;
    p[1] = p_l;
    rho[N] = rho_r;
    u[N] = u_r;
    p[N] = p_r;
    //PDEs
    W[1, :] = rho;
    W[2, :] = rho .* u;
    W[3, :] = E;
    F[1, :] = rho .* u;
    F[2, :] = rho .* u .^ 2 + p;
    F[3, :] = u .* (E + p);
    //state equation
    E = p ./ (gamma - 1.0) + rho .* u .^ 2 / 2.0;
    //  u_s = sqrt(gamma * p ./ rho);
  end eulerEq;

  model Riemann1
    extends eulerEq(rho_l = 1, u_l = 0.75, p_l = 1, rho_r = 0.125, u_r = 0, p_r = 0.1, x_0 = 0.3, N = 1000, dt = 0.0002, alpha = 0.4);
    //euler, N = 200 (dx = 0.005, dt = 0.0001, alpha = 0.01 - celkem maká, hodně difuse, trochu osciluje
    //euler, N = 1000, dt = 2e-5, alpha = 0.01 - dobrý, malinko osciluje na čele první vlny
    //radau1, N = 100, dt = 0.002, alpha = 0.01 - vypadá nejlíp
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 0.0002));
  end Riemann1;

  model advectionCos
    extends advection(M = 1, N = 1600, dt = 0.0003125);
  initial equation
    u = array(if x[i] < 0.25 then cos(Modelica.Constants.pi / 2 * 4 * x[i]) else 0 for i in 1:N);
  equation
    //BC:
    u[1] = 1;
    u[N] = 0;
    annotation(experiment(StartTime = 0, StopTime = 0.4, Tolerance = 1, Interval = 0.0003125));
  end advectionCos;

  model advectionStep
    extends advection(M = 1, N = 400, dt = 0.0005);
    parameter Real ul = 1, ur = 0;
  initial equation
    u = array(if x[i] < 0.2 then ul else ur for i in 1:N);
  equation
    //BC:
    u[1] = ul;
    u[N] = ur;
    annotation(experiment(StartTime = 0, StopTime = 0.4, Tolerance = 1, Interval = 0.0005));
  end advectionStep;
  annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
end conservationLaws1D;