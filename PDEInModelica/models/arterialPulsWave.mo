model arterialPulsWave
  import PDEDomains.*;
  import C = Modelica.Constants;
  parameter Real L = 1;
  parameter DomainLineSEgment1D omega(length = L);
  field Real A(domain = omega);
  field Real U(domain = omega, start = MAP);
  field Real P(domain = omega, start = CO);
  parameter Real alpha = 1.1;
  parameter Real rho = 1000;
  parameter Real zeta = (2-alpha)/(alpha-1);
  field Real f;
  parameter Real mu = 4e-3;
  parameter Real P_ext = 0;
  parameter Real A_0 = 24e-3;
  parameter Real beta = 4/3*sqrt(C.Pi)*h*E;
  parameter Real h = 0.002; //vessel wall thicknes [m]
  parameter Real E = 6500000.0; //vessel Young's modulus [Pa]
  parameter Real CO = 5.6/1000/60;
  parameter Real MAP=90*133.322387415;
  parameter Real R_out = MAP/CO; //right bc output resistence
  input Real Q_heart;
  
  
equation
  pder(A,time) + pder(A*U,x) = 0                                       in omega;
  pder(U,time) + (2*alpha-1)*U*pder(U,x) + (alpha-1)*U*U/A*pder(A,x) 
                                         + 1/rho*pder(P,x) = f/(rho*A) in omega;
  f = -2*(zeta+2)*mu*C.pi*U                                            in omega;
  P = P_ext + beta/A_0*(sqrt(A) - sqrt(A_0))                           in omega;
  Q = Q_heart;                                                         in omega.left;
  Q = P/R_out;                                                         in omega.right;
  
  
  


end arterialPulsWave;
