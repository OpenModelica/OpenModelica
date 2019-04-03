model BatchReactor
  // see: Biegler: Nonlinear Programming Concepts, Algorithms and
  //               Applications to Chemical Processes, MOS-SIAM 2010
  parameter Real a = 1;
  parameter Real b = 1;

  Real x2;
  Real x1;
  Real y2(start =0, fixed=true, min=0, max=1/a, nominal = 1/a);
  Real y1(start =1/b, fixed=true, min=0, max=1/b, nominal = 1/b);

  input Real u(min=0, max = 5.0, nominal = 1.0,start = 1.0);
equation
  x2 = a*y2;
  x1 = b*y1;
  b*der(y1) = -(u+u^2/2)*x1;
  a*der(y2) = u*x1;
end BatchReactor;

optimization nmpcBatchReactor_scaling(objective = cost)
  Real cost = -a*y2;
  extends BatchReactor(a = 1e10, b = 1e-10);
end nmpcBatchReactor_scaling;

optimization nmpcBatchReactor(objective = cost)
  Real cost = -a*y2;
  extends BatchReactor(a = 1, b = 1);
end nmpcBatchReactor;

optimization nmpcBatchReactorCon(objective = cost)
  Real cost = -a*y2;
  Real con = 4.0*sin(time)^2+1;
  extends BatchReactor(a = 1, b = 1);
constraint
  u <= con;
  time <= 1;
end nmpcBatchReactorCon;
