model LotkaVolterra
  Real x(start=5),y(start=3);
  parameter Real mu1=5,mu2=2;
  parameter Real lambda1=3,lambda2=1;
equation
  0 = x*(mu1-lambda1*y) - der(x);
  0 = -y* (mu2 -lambda2*x) - der(y);
end LotkaVolterra;
