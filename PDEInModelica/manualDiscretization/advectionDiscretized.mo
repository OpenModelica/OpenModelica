model advectionDiscretized
  // u_t + u_x = 0
  constant Integer N = 100;
  parameter Real[N] x = array(i * dx for i in 0:N - 1);
  Real[N] u, u_x;
  parameter Real L = 1, dx = L / (N - 1);
initial equation
  for i in 2:N - 1 loop
    //initial conditions:
    u[i] = 0;
  end for;
equation
  //unused:
  u_x[1] = 0;
  u_x[N] = 0;
  //left BC:
  u[1] = sin(2 * 3.14 * time);
  for i in 2:N - 1 loop
    //discretization of spatial derivative:
    u_x[i] = (u[i + 1] - u[i - 1]) / dx;
    // the equation
    der(u[i]) + u_x[i] = 0;
  end for;
  //extrapolation in the last node
  u[N] = 2 * u[N - 1] - u[N - 2];
end advectionDiscretized;