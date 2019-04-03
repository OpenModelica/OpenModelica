model Riccati
  parameter Real A[2,2]={{-1,0},{0,-1}};
  parameter Real B[2,1]={{1},{1}};
  parameter Real Q[2,2]={{1,0},{1,0}};
  Real X[2,2];

equation
  zeros(2, 2)=transpose(A)*transpose(X) + X*A - X*B*transpose(B)*X + Q "Algebraic Riccati Equation";
end Riccati;

