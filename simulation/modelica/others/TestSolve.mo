model ModelTestSolve
  Real x,y,z;
equation
  ( 1 / x ) * 2 = 1;
  ( y / 1 ) * 2 = 1;
  4 = ( 1 / z ) * 3;
end ModelTestSolve;

model ModelTestSolve2
  Real[12] x(each start = -1);
  Real y[:] = array(-1 * (-1) ^ i * min(max(abs((-1) ^ i * time ^ i + sin(time ^ i) + cos(i * time) + i), 1e-5), 10 + sin(time ^ i)) for i in 1:10);
equation
  x[1] * y[2] + y[3] * x[1] + y[4] * x[1] * y[3] + y[5] * (x[1] * y[4]) + y[7] * y[1] * y[9] * x[1] + y[1] * x[1] ^ 1 = 10 ^ time;
  sqrt(x[2] + y[1] * x[2]) = time;
  x[3] ^ 3 = x[2];
  (x[4] * y[1]) ^ 3 * x[4] ^ 4 = x[2];
  exp(y[3] * sinh(x[5]) + time) = 1;
  abs(x[6] - sin(time)) = 0;
  x[7] = time * x[7] ^ (-2);
  abs((x[8] + x[8]*exp(sum(y))-(10-(sum(y))))) ^ 2 = 0;
  x[9]*(x[8]+10) = time-1;
  (if time < 0 then tanh((sinh((log(x[10]-1))^5-1))^3-1) else x[10]) = 10;
  x[11] = sqrt(delay(x[11],0.01) + time);
  exp(x[12]) * y[2] + y[3] * exp(x[12]) + y[4] * exp(x[12]) * y[3] + y[5] * (x[1] * y[4]) + y[7] * y[1] * y[9] * exp(x[12]) + y[1] * exp(x[12]) ^ 1 = 10 ^ time;

end ModelTestSolve2;

model ModelTestSolve3
  Real x,y,z,w,v;
equation
  sin(x) = sqrt(-cos(x)^2 + x);
  sinh(y)/cosh(y) = min(time+0.5,10/11);
  exp(log(sqrt(z))) = exp(log(sqrt(3*z+time)));
  y*sinh(w) = z*cosh(w);
  cosh(v*(w+1) + time*10) = sinh(v*(w+1)+time*10);
end ModelTestSolve3;



model ModelTestSolve4
"
test: cosh, sinh, tanh
"
  constant Real s[:] = {-1,1};
  Real[2] x(start=s);
  Real[2] y(start=s);
  Real[2] z(start=s);
  Real err[6];
  Real Err (start = 0, fixed = true);
equation
  for i in 1:2 loop
    cosh(x[i]) = 1.1 + 0.5*time;
    sinh(y[i]) = 1.1 + 0.5*time;
    tanh(z[i]) = 0.5*time;
    err[(i-1)*3 +1] = abs(-cosh(x[i]) + 1.1 + 0.5*time);
    err[(i-1)*3 +2] = abs(-sinh(y[i]) + 1.1 + 0.5*time);
    err[(i-1)*3 +3] = abs(-tanh(z[i]) +  0.5*time);
  end for;

  der(Err) = sum(err);
end ModelTestSolve4;


model ModelTestSolve5
"
test: cos, sin, tan
"
  constant Real s[:] = {-1,1};
  Real[2] x(start=s);
  Real[2] y(start=s);
  Real[2] z(start=s);
  Real err[6];
  Real Err (start = 0, fixed = true);
equation

  for i in 1:2 loop
    cos(x[i]) = 0.5*time;
    sin(y[i]) = 0.5*time;
    tan(z[i]) = 0.5*time;
    err[(i-1)*3 +1] = abs(-cos(x[i]) + 0.5*time);
    err[(i-1)*3 +2] = abs(-sin(y[i]) + 0.5*time);
    err[(i-1)*3 +3] = abs(-tan(z[i]) + 0.5*time);
  end for;

  der(Err) = sum(err);
end ModelTestSolve5;

model ModelTestSolve6
  Real x(start=0);
  Real y(start=4);
  Real z(start=10);
  Real w;
equation
  cos(x) = time;
  cos(y) = time;
  cos(z) = time;
  w = acos(time);
end ModelTestSolve6;

model ModelTestSolve7
  Real x(start=0);
  Real y(start=4);
  Real z(start=10);
  Real w;
equation
  sin(x) = time;
  sin(y) = time;
  sin(z) = time;
  w = asin(time);
end ModelTestSolve7;

model ModelTestSolve8
  Real x(start=0);
  Real y(start=4);
  Real z(start=10);
  Real w;
equation
  tan(x) = time;
  tan(y) = time;
  tan(z) = time;
  w = atan(time);
end ModelTestSolve8;

model ModelTestSolve9
  Real x(start=-1);
  Real y(start=-4);
  Real z(start=-10);
  Real w;
equation
  cos(x) = time;
  cos(y) = time;
  cos(z) = time;
  w = acos(time);
end ModelTestSolve9;

model ModelTestSolve10
  Real x(start=-1);
  Real y(start=-4);
  Real z(start=-10);
  Real w;
equation
  sin(x) = time;
  sin(y) = time;
  sin(z) = time;
  w = asin(time);
end ModelTestSolve10;

model ModelTestSolve11
  Real x(start=0);
  Real y(start=4);
  Real z(start=10);
  Real w;
equation
  tan(x) = time;
  tan(y) = time;
  tan(z) = time;
  w = atan(time);
end ModelTestSolve11;

model ModelTestSolve12
  Real x(start=-1);
  Real y;
  Real z(start=6);
  Real v(start=-6);
  Real w;
equation
  z = sin(time)^2;
  y = cos(z);
  cos(x+cos(z)+w) = time;
  cos(x+cos(v)+w) = time;
  w = acos(time);
end ModelTestSolve12;

model ModelTestSolve13
  Real x(start=-1);
  Real y;
  Real z(start=6);
  Real v(start=-6);
  Real w;
equation
  z = sin(time)^2;
  y = cos(z);
  cos(x+z+w) = time;
  cos(x+v+w) = time;
  w = acos(time);
end ModelTestSolve13;

model ModelTestSolve14
  Real x(start=-1);
  Real y;
  Real z(start=6);
  Real v(start=-6);
  Real w;
equation
  abs(z) = sin(time)^2;
  abs(y) = cos(z);
  abs(cos(x+z+w)) = time;
  abs(cos(x+v+w)) = time;
  abs(w) = acos(time);
end ModelTestSolve14;

model ModelTestSolve15
  Real x(start=-1);
  Real y(start=1);
  Real z(start=6);
  Real v(start=-6);
  Real w(start = 5);
equation
  (z)^4 = exp(time)^2;
  (y)^2 = exp(cos(z));
  (log(abs(x+z+w)))^(exp(z)+1) = exp(time);
  (log(abs(x+v+w)))^(exp(z)+1) = exp(time);
  abs(w) = exp(acos(time));
end ModelTestSolve15;

model ModelTestSolve16
  Real x(start=-1);
  Real y(start=1);
  Real z(start=6);
  Real v(start=-6);
  Real w(start = 5);
  Real a1,a2;
equation
  (z)^4 = exp(time)^2;
  (y)^2 = exp(cos(z));
  (log(abs(x+z+w)))^(exp(z)+1) = exp(time);
  (log(abs(x+v+w)))^(exp(z)+1) = exp(time);
  abs(w) = exp(acos(time));
  a1 = abs(x+z+w);
  a2 = abs(x+v+w);
end ModelTestSolve16;

model ModelTestSolve17
  Real x,y,z(start=2),w,v;
  Real res(start=0,fixed=true);
equation
  (1/x)^4 = exp(time+1);
  (1/x + log10(y))^(max(abs(x),4)) = max(sqrt(exp(2+7*time)),50);
  (exp(sqrt(1-z)))^(x) = x^2+time+1;
  log(sqrt(((v-1))+1/y))^20 = y^2*exp(-10*time-100);
  (sin(1/x + 1/v + 1/(sqrt(abs(z)/(z^2))) + 1/z) + sin(1/x) + sqrt(abs(v-1))*sqrt(w-1))^x = 0;

  der(res) = abs((1/x)^4 - exp(time+1)) + abs( (1/x + log10(y))^(max(abs(x),4)) - max(sqrt(exp(2+7*time)),50))
             + abs((exp(sqrt(1-z)))^(x) -( x^2+time+1)) + abs(log(sqrt(((v-1))+1/y))^20 - y^2*exp(-10*time-100))
             + abs((sin(1/x + 1/v + 1/(sqrt(abs(z)/(z^2))) + 1/z) + sin(1/x) + sqrt(abs(v-1))*sqrt(w-1))^x);
end ModelTestSolve17;

model ModelTestSolve18
  parameter Real x(fixed=false),y(fixed=false);
  Real z;
initial equation
  time = 5*(exp(sign(2*x + 1))-1);
  time = y*(exp(if y>0 then time else 2*time))-1;
equation
  der(z) = x-y;
end ModelTestSolve18;


