model arterialPulsWave
  import PDEDomains.*;
  import C = Modelica.Constants;
  parameter Real L = 1;
  parameter DomainLineSegment1D omega(length = L);
  field Real A(domain = omega);
  field Real U(domain = omega);
  field Real P(domain = omega, start = MAP);
  field Real f;
  parameter Real alpha = 1.1;
  parameter Real rho = 1000;
  parameter Real zeta = (2-alpha)/(alpha-1);
  parameter Real mu = 4e-3;
  parameter Real P_ext = 0;
  parameter Real A_0 = 24e-3;
  parameter Real beta = 4/3*sqrt(C.Pi)*h*E;
  parameter Real h = 0.002; //vessel wall thicknes [m]
  parameter Real E = 6500000.0; //vessel Young's modulus [Pa]
  parameter Real CO = 5.6/1000/60;
  parameter Real MAP=90*133.322387415;
  input Real Q_heart;
initial equation
  U*A = CO                                                      in omega;
equation
  der(A,time) + der(A*U,x) = 0;        //4 -> A_t (utFun)
  der(U,time) + (2*alpha-1)*U*der(U,x) + (alpha-1)*U*U/A*pder(A,x)
                                  + 1/rho*pder(P,x) = f/(rho*A);//3 -> U_t (utFun)
  f = -2*(zeta+2)*mu*C.pi*U;        //2 -> f (vFun)
  P = P_ext + beta/A_0*(sqrt(A) - sqrt(A_0));    //1 -> P (vFun)
  A*U = Q_heart;                                          in omega.left;
  A*U = CO;                                               in omega.right;
end arterialPulsWave;
