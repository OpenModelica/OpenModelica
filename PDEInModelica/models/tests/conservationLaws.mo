package conservationLaws
  model conservationLaw
    constant Integer M;
    constant Integer N = 800;
    parameter Real L = 1;
    parameter Real dx = L / (N - 1);
    parameter Real[N] x = array(i * dx for i in 0:N - 1);
    Real[M, N] W, F;
    Real[M, N] F_x;
  equation
    //BCs?
    for i in 2:N - 1 loop
      //discretization of spatial derivative:
      F_x[:, i] = (F[:, i + 1] - F[:, i - 1]) / (2 * dx);
      der(W[:, i]) + F_x[:, i] = {0.0};
    end for;
    // the equation:
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1e-06, Interval = 0.005));
  end conservationLaw;

  model pokusy
    parameter Real[2, 3] A = {{1, 2, 3}, {4, 5, 6}};
    parameter Real As[2] = A[:, 2];
  end pokusy;

  model advection
    extends conservationLaw(M = 1);
    Real u[N];
    parameter Real a = 1, ul = 1, ur = 0;
  initial equation
    u = array(if i < N / 2 then ul else ur for i in 1:N);
  equation
    //BCs
    u[1] = ul;
    u[N] = ur;
    //dummy BCs
    F_x[1, 1] = 0;
    F_x[1, N] = 0;
    //equations
    W[1, :] = u;
    F[1, :] = a * u;
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1e-06, Interval = 0.000625));
  end advection;
  annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
end conservationLaws;