package conservationLaws2D
  model conservationLaw
    constant Integer M, Nx, Ny;
    parameter Real Lx = 1, Ly = 1;
    parameter Real dx = Lx / (Nx - 1), dy = Ly / (Ny - 1);
    parameter Real[Nx] x = array(i * dx for i in 0:Nx - 1);
    parameter Real[Ny] y = array(i * dy for i in 0:Ny - 1);
    Real[M, Nx, Ny] W, Fx, Fy;
    Real[M, Nx, Ny] Fx_x, Fy_y;
  end conservationLaw;

  model conservationLawCentral
    extends conservationLaw;
    parameter Real dt;
  equation
    //dummy BCs
    Fx_x[1, 1, :] = zeros(Ny);
    Fx_x[1, Nx, :] = zeros(Ny);
    Fx_x[1, 2:Nx - 1, 1] = zeros(Nx - 2);
    Fx_x[1, 2:Nx - 1, Ny] = zeros(Nx - 2);
    Fy_y[1, 1, :] = zeros(Ny);
    Fy_y[1, Nx, :] = zeros(Ny);
    Fy_y[1, 2:Nx - 1, 1] = zeros(Nx - 2);
    Fy_y[1, 2:Nx - 1, Ny] = zeros(Nx - 2);
    for i in 2:Nx - 1 loop
      for j in 2:Ny - 1 loop
        //discretization of spatial derivative:
        Fx_x[:, i, j] = (Fx[:, i + 1, j] - Fx[:, i - 1, j]) / (2 * dx);
        Fy_y[:, i, j] = (Fy[:, i, j + 1] - Fy[:, i, j - 1]) / (2 * dy);
        // the equation:
        der(W[:, i, j]) + Fx_x[:, i, j] + Fy_y[:, i, j] = zeros(M);
      end for;
    end for;
  end conservationLawCentral;

  model advection
    extends conservationLawCentral(M = 1);
    Real u[Nx, Ny];
    parameter Real ax = 1, ay = 1;
  initial equation
    //cos BC
    //array(if x[i] < 0.25 then cos(Modelica.Constants.pi / 2 * 4 * x[i]) else 0 for i in 1:Nx);
    //step BC
    //
  equation
    //equations
    W[1, :, :] = u;
    Fx[1, :, :] = ax * u;
    Fy[1, :, :] = ay * u;
  end advection;

  model advectionCos
    extends advection(Nx = 3, Ny = 3, dt = 0.002);

    function icfun
      input Real x, y;
      output Real u;
    protected
      Real r;
    algorithm
      r := sqrt(x ^ 2 + y ^ 2);
      u := if r < 0.25 then cos(Modelica.Constants.pi / 2 * 4 * r) else 0;
    end icfun;
  initial equation
    u = array(icfun(x[i], y[j]) for i in 1:Nx, j in 1:Ny);
  equation
    //BC:
    u[1, :] = array(icfun(x[1], y[j]) for j in 1:Ny);
    u[Nx, :] = zeros(Ny);
    u[2:Nx - 1, 1] = array(icfun(x[i], y[1]) for i in 2:Nx - 1);
    u[2:Nx - 1, Ny] = zeros(Nx - 2);
    annotation(experiment(StartTime = 0, StopTime = 0.4, Tolerance = 1, Interval = 0.0003125));
  end advectionCos;

  /*
                                                    model conservationLawLF
                                                      parameter Real dt;
                                                      parameter Real alpha = 1;
                                                      extends conservationLaw;
                                                    equation
                                                      for i in 2:Nx - 1 loop
                                                        //discretization of spatial derivative:
                                                        F_x[:, i] = (F[:, i + 1] - F[:, i - 1]) / (2 * dx);
                                                        // the equation:
                                                        der(W[:, i]) - alpha * (W[:, i + 1] - 2 * W[:, i] + W[:, i - 1]) / (2 * dt) + F_x[:, i] = zeros(M);

                                                      end for;
                                                    end conservationLawLF;

                                                    model eulerEq
                                                      extends conservationLawLF(M = 3);
                                                      Real[Nx] rho, u, p, E;
                                                      //  parameter Real u_s;
                                                      parameter Real gamma = 1.4, x_0, T;
                                                      parameter Real rho_l, u_l, p_l;
                                                      parameter Real rho_r, u_r, p_r;
                                                    initial equation
                                                      rho = array(if x[i] < x_0 then rho_l else rho_r for i in 1:Nx);
                                                      u = array(if x[i] < x_0 then u_l else u_r for i in 1:Nx);
                                                      p = array(if x[i] < x_0 then p_l else p_r for i in 1:Nx);
                                                    equation
                                                      //dummy BCs
                                                      F_x[:, 1] = zeros(M);
                                                      F_x[:, Nx] = zeros(M);
                                                      //BCs
                                                      rho[1] = rho_l;
                                                      u[1] = u_l;
                                                      p[1] = p_l;
                                                      rho[Nx] = rho_r;
                                                      u[Nx] = u_r;
                                                      p[Nx] = p_r;
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
                                                      extends eulerEq(rho_l = 1, u_l = 0.75, p_l = 1, rho_r = 0.125, u_r = 0, p_r = 0.1, x_0 = 0.3, Nx = 1000, dt = 0.0002, alpha = 0.4);
                                                      //euler, Nx = 200 (dx = 0.005, dt = 0.0001, alpha = 0.01 - celkem maká, hodně difuse, trochu osciluje
                                                      //euler, Nx = 1000, dt = 2e-5, alpha = 0.01 - dobrý, malinko osciluje na čele první vlny
                                                      //radau1, Nx = 100, dt = 0.002, alpha = 0.01 - vypadá nejlíp
                                                      annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 0.0002));
                                                    end Riemann1;



                                                    model advectionStep
                                                      extends advection(M = 1, Nx = 400, dt = 0.0005);
                                                      parameter Real ul = 1, ur = 0;
                                                    initial equation
                                                      u = array(if x[i] < 0.2 then ul else ur for i in 1:Nx);
                                                    equation
                                                      //BC:
                                                      u[1] = ul;
                                                      u[Nx] = ur;
                                                      annotation(experiment(StartTime = 0, StopTime = 0.4, Tolerance = 1, Interval = 0.0005));
                                                    end advectionStep;
                                                  */
  annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
end conservationLaws2D;