model advectionDiscretizedTest
  // u_t + c*u_x = 0
  constant Integer N = 800;
  parameter Real L = 1;
  parameter Real dx = L / (N - 1);
  parameter Real[N] x = array(i * dx for i in 0:N - 1);
  Real[N] u, u_x;
  parameter Real c = 1;
initial equation
  for i in 2:N - 1 loop
    //initial conditions:
    u[i] = 0;
  end for;
equation
  //unused array elements, eqs. just for balanced system:
  u_x[1] = 0;
  u_x[N] = 0;
  for i in 2:N - 1 loop
    //discretization of spatial derivative:
    u_x[i] = (u[i + 1] - u[i - 1]) / (2 * dx);
    //u_x[i] = (u[i] - u[i - 1]) / dx;
    // the equation:
    der(u[i]) + c * u_x[i] = 0;
  end for;
  //left BC:
  u[1] = 1.0;
  //1.0;
  //sin(2 * 3.14 * time);
  //extrapolation in the last node
  u[N] = 2 * u[N - 1] - u[N - 2];
end advectionDiscretizedTest;