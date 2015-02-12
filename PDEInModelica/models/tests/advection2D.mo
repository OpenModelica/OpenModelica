package advection2D
  model advectionBase
    constant Integer Nx = 40, Ny = 40;
    parameter Real Lx = 10, Ly = 10;
    parameter Real dx = Lx / (Nx - 1), dy = Ly / (Ny - 1);
    parameter Real[Nx] x = array(i * dx for i in 0:Nx - 1);
    parameter Real[Ny] y = array(i * dy for i in 0:Ny - 1);
    Real[Nx, Ny] u;
    Real[Nx, Ny] u_x;
    Real[Nx, Ny] u_y;
    parameter Real ax = 1, ay = 1;
  equation
    //boundary:
    ///dummy:
    u_x[1, :] = zeros(Ny);
    u_x[Nx, :] = zeros(Ny);
    u_x[2:Nx - 1, 1] = zeros(Nx - 2);
    u_x[2:Nx - 1, Ny] = zeros(Nx - 2);
    u_y[1, :] = zeros(Ny);
    u_y[Nx, :] = zeros(Ny);
    u_y[2:Nx - 1, 1] = zeros(Nx - 2);
    u_y[2:Nx - 1, Ny] = zeros(Nx - 2);
    //interior:
    for i in 2:Nx - 1 loop
      for j in 2:Ny - 1 loop
        //differences
        u_x[i, j] = (u[i + 1, j] - u[i - 1, j]) / (2 * dx);
        u_y[i, j] = (u[i, j + 1] - u[i, j - 1]) / (2 * dy);
        //equations
        der(u[i, j]) + ax * u_x[i, j] + ay * u_y[i, j] = 0;
      end for;
    end for;
  end advectionBase;

  function icfun
    input Real x, y;
    output Real u;
  protected
  algorithm
    u := 0;
  end icfun;

  model advectionZero
    extends advectionBase;
  initial equation
    u[2:Nx - 1, 2:Ny - 1] = zeros(Nx - 2, Ny - 2);
  equation
    u[1, :] = zeros(Ny);
    u[Nx, :] = zeros(Ny);
    u[2:Nx - 1, 1] = zeros(Nx - 2);
    u[2:Nx - 1, Ny] = zeros(Nx - 2);
  end advectionZero;

  model advectionCosPeak
    extends advectionBase;
  initial equation
    for i in 2:Nx - 1, j in 2:Ny - 1 loop
      u[i, j] = if sqrt((x[i] - 2) ^ 2 + (y[j] - 2) ^ 2) < 1 then cos(Modelica.Constants.pi / 2 * sqrt((x[i] - 2) ^ 2 + (y[j] - 2) ^ 2)) else 0;
    end for;
  equation
    u[1, :] = zeros(Ny);
    u[Nx, :] = zeros(Ny);
    u[2:Nx - 1, 1] = zeros(Nx - 2);
    u[2:Nx - 1, Ny] = zeros(Nx - 2);
    annotation(experiment(StartTime = 0, StopTime = 0.2, Tolerance = 1, Interval = 0.05));
  end advectionCosPeak;
end advection2D;