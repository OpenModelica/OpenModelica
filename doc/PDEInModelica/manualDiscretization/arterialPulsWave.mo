model arterialPulsWave
  constant Real pi = Modelica.Constants.pi;
  constant Integer N = 80;
  parameter Integer NN = N;
  constant Real L = 10;
  constant Real dx = L / (N - 1);
  constant Real x[N] = array(dx * i for i in 1:N);
  constant Real Pa2mmHgR = 133.322387415;
  parameter Real rho = 1000;
  parameter Real f = 0;
  parameter Real alpha = 0;
  parameter Real h0 = 0.002;
  parameter Real E = 6500000.0;
  parameter Real nu = 1 / 2;
  parameter Real beta = (sqrt(pi) * h0 * E) / ((1 - nu ^ 2) * A0);
  parameter Real Pext = 0;
  parameter Real A0 = pi * 0.012 ^ 2;
  parameter Real HR = 70 / 60;
  parameter Real Tc = 1 / HR;
  parameter Real MAP = 90 * Pa2mmHgR;
  parameter Real CO = 5.6 / 1000 / 60;
  parameter Real SV = CO / HR;
  parameter Real Qmax = (3 * pi * SV) / (2 * Tc);
  parameter Real Rout = MAP / CO;
  parameter Real AInit = ((MAP - Pext) / beta + sqrt(A0)) ^ 2;
  Real A[N](each start = AInit, each fixed = true);
  Real A_x[N];
  Real Q[N];
  Real u[N];
  Real Q_x[N];
  Real P[N];
  Real P_x[N];
  Real tp;
  //  parameter Integer T = 100;
  //  discrete Real Q_d[T];
initial equation
  for i in 2:N - 1 loop
  Q[i] = CO;

  end for;
equation
  //  when sample(0, 1 / T) then
  //      Q_d[Integer(time * T)] = Q[50];
  //  end when;
  tp = mod(time, Tc);
  Q[1] = if tp < Tc / 3 then Qmax * sin((3 * Modelica.Constants.pi * tp) / Tc) ^ 2 else 0;
  A_x[1] = (A[2] - A[1]) / dx;
  Q_x[1] = (Q[2] - Q[1]) / dx;
  for i in 2:N - 1 loop
  Q_x[i] = (Q[i + 1] - Q[i - 1]) / (2 * dx);
  A_x[i] = (A[i + 1] - A[i - 1]) / (2 * dx);

  end for;
  for i in 1:N loop
  der(A[i]) + Q_x[i] = 0;

  end for;
  for i in 2:N - 1 loop
  der(Q[i]) + alpha * ((2 * Q[i] * Q_x[i]) / A[i] - (Q[i] ^ 2 * A_x[i]) / A[i] ^ 2) + A[i] / rho * P_x[i] = f / rho;

  end for;
  P = ones(N) * Pext + beta * (sqrt(A) - ones(N) * sqrt(A0));
  P_x = (beta / 2 * A_x) ./ sqrt(A);
  u = Q ./ A;
  Q[N] = CO;
  A_x[N] = (A[N] - A[N - 1]) / dx;
  Q_x[N] = (Q[N] - Q[N - 1]) / dx;
  annotation(experiment(StartTime = 0.0, StopTime = 1.0, Tolerance = 0.0001));
end arterialPulsWave;

