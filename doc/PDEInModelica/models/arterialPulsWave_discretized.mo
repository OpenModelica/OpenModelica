model arterialPulsWave
  constant Integer N=120;
  constant Real L=4;
  constant Real dx=L/(N - 1);
  constant Real x[N]=array(dx*i for i in 1:N);
  constant Real Pa2mmHgR=133.322387415;
  parameter Real rho=1000;
  parameter Real f=0;
  parameter Real alpha=0;
  parameter Real h0=0.002;
  parameter Real E=6500000000.0;
  parameter Real nu=1/2;
  parameter Real beta=sqrt(Modelica.Constants.pi)*h0*E/((1 - nu^2)*A0);
  parameter Real Pext=0;
  parameter Real A0=Modelica.Constants.pi*0.012^2;
  parameter Real HR=70/60;
  parameter Real Tc=1/HR;
  parameter Real MAP=90*Pa2mmHgR;
  parameter Real CO=5.6/1000/60;
  parameter Real SV=CO/HR;
  parameter Real Qmax=3*Modelica.Constants.pi*SV/(2*Tc);
  parameter Real Rout=MAP/CO;
  parameter Real AInit=((MAP - Pext)/beta + sqrt(A0))^2;
  Real A[N](each start=AInit, each fixed=true);
  Real Q[N];
  Real u[N];
  Real P[N];
  Real tp;
//initial conditions:
initial equation
  for i in 2:N - 1 loop
    Q[i]=CO;
  end for;
equation
//border conditions:
  tp=mod(time, Tc);
  Q[1]=if tp < Tc/3 then Qmax*sin(3*Modelica.Constants.pi*tp/Tc)^2 else 0;
  A_x[1]=(A[2] - A[1])/dx;
  Q_x[1]=(Q[2] - Q[1])/dx;

  Q[N]=0;
  A_x[N]=(A[N] - A[N - 1])/dx;
  Q_x[N]=(Q[N] - Q[N - 1])/dx;

//equations
  pder(A,t) + pder(Q,x) = 0 ??in omega;
  pder(Q,t) + alpha*(2*Q*pder(Q,x)/A - Q^2*pder(A,x)/A^2) + A/rho*pder(P,x) = f/rho ?? in omega;
  P = Pext + beta*(sqrt(A) - sqrt(A0));
//  pder(P,x) = beta/2*pder(A,x)/sqrt(A); - generate automaticaly by deriving the above equation
  u = Q/A;
end arterialPulsWave;
