within ;
model TestSpatialDiscretization
  model Test1
    import Modelica.Constants.pi;
    parameter Real f0 = 9;
    parameter Real f1 = 7;
    Real w01(start = 1, fixed = true);
    Real w02(start = 0, fixed = true);
    Real w11(start = 1, fixed = true);
    Real w12(start = 0, fixed = true);
    Real in0, in1, out0, out1;
    Real x(start = 0, fixed = true);
    Real v;
    Real w01_exact = cos(2*pi*f0*time);
    Real w11_exact = cos(2*pi*f1*time);
    Real out1_exact = if time < 0.35 then 0
                      elseif time < 0.5 then cos(2*pi*f0*(time - 0.25))
                      else in1;
    Real out0_exact = if time < 0.5 then in0 else
                      if time < 0.75 then cos(2*pi*f0*(0.5 - (time - 0.5))) else
                      cos(2*pi*f1*(time - 0.25));
    Real err0(start = 0, fixed = true);
    Real err1(start = 0, fixed = true);
    Boolean isPosVel;
  equation
    der(w01) = w02;
    der(w02) = -(2*pi*f0)^2*w01;
    der(w11) = w12;
    der(w12) = -(2*pi*f1)^2*w11;
    der(x) = v;
    v = if time < 0.5 then 4 else -4;
    in0 = if time < 0.1 then 0 else w01;
    in1 = if time < 0.1 then 0 else w11;
    isPosVel = v > 0;
    (out0, out1) = spatialDistribution(in0, in1, x, isPosVel, {0, 1}, {0, 0});
    der(err0) = (out0_exact - out0)^2;
    der(err1) = (out1_exact - out1)^2;
    assert(err0 < 1e-3, "Numerical solution too far from exact one");
    assert(err1 < 1e-3, "Numerical solution too far from exact one");

   annotation(uses(Modelica(version="3.2.3")),
             experiment(stopTime = 2, Interval = 1e-4, Tolerance = 1e-7));
  end Test1;

  model Test2
    import Modelica.Constants.pi;
    parameter Real f0 = 9;
    parameter Real f1 = 7;
    parameter Real z0 = 1;
    Real w01(start = 1, fixed = true);
    Real w02(start = 0, fixed = true);
    Real w11(start = 1, fixed = true);
    Real w12(start = 0, fixed = true);
    Real in0, in1, out0, out1;
    Real x(start = 0, fixed = true);
    Real v;
    Real w01_exact = cos(2*pi*f0*time);
    Real w11_exact = cos(2*pi*f1*time);
    Real out1_exact = if time < 0.35 then z0 else
                      if time < 0.5 then z0 + cos(2*pi*f0*(time - 0.25))
                      else in1;
    Real out0_exact = if time < 0.5 then in0 else
                      if time < 0.75 then z0 + cos(2*pi*f0*(0.5 - (time - 0.5))) else
                      z0 + cos(2*pi*f1*(time - 0.25));
    Real err0(start = 0, fixed = true);
    Real err1(start = 0, fixed = true);
    Boolean isPosVel;
  equation
    der(w01) = w02;
    der(w02) = -(2*pi*f0)^2*w01;
    der(w11) = w12;
    der(w12) = -(2*pi*f1)^2*w11;
    der(x) = v;
    v = if time < 0.5 then 4 else -4;
    in0 = if time < 0.1 then z0 else z0+w01;
    in1 = if time < 0.1 then z0 else z0+w11;
    isPosVel = v > 0;
    (out0, out1) = spatialDistribution(in0, in1, x, isPosVel, {0, 1}, {z0, z0});
    der(err0) = (out0_exact - out0)^2;
    der(err1) = (out1_exact - out1)^2;
    assert(err0 < 1e-3, "Numerical solution too far from exact one");
    assert(err1 < 1e-3, "Numerical solution too far from exact one");

   annotation(uses(Modelica(version="3.2.3")),
             experiment(stopTime = 2, Interval = 1e-4, Tolerance = 1e-7));
  end Test2;

  model Test3
    import Modelica.Constants.pi;
    parameter Real f0 = 20;
    parameter Real f1 = 4;
    parameter Real z0 = 0.1;
    Real w01(start = 1, fixed = true);
    Real w02(start = 0, fixed = true);
    Real w11(start = 1, fixed = true);
    Real w12(start = 0, fixed = true);
    Real in0, in1, out0, out1;
    Real x(start = 0, fixed = true);
    Real v;
    Real w01_exact = cos(2*pi*f0*time);
    Real w11_exact = cos(2*pi*f1*time);
    Real aux1 = (if time < 0.5 then 0 else
                 if time < 0.75 then cos(2*pi*f0*(time + (-4*time +3 + sqrt(16*time^2-24*time+17))/4)) else
                 in1);
    Real out1_exact = if time < 0.5 then z0 elseif aux1 < 0.5 then aux1 else z0;
    Real aux0 = (if time < 0.75 + sqrt(2)/2 then in0 else
                 cos(2*pi*f1*(time + (-4*time +3 + sqrt(16*time^2-24*time+1))/4)));
    Real out0_exact = if aux0 < 0.5 then aux0 else z0;
    Real err0(start = 0, fixed = true);
    Real err1(start = 0, fixed = true);
    Boolean isPosVel;
  equation
    der(w01) = w02;
    der(w02) = -(2*pi*f0)^2*w01;
    der(w11) = w12;
    der(w12) = -(2*pi*f1)^2*w11;
    der(x) = v;
    v = 3 - 4*time;
    in0 = if w01 <= 0.5 then w01 else z0;
    in1 = if w11 <= 0.5 then w11 else z0;
    isPosVel = v > 0;
    (out0, out1) = spatialDistribution(in0, in1, x, isPosVel, {0, 1}, {z0, z0});
    der(err0) = (out0_exact - out0)^2;
    der(err1) = (out1_exact - out1)^2;
    assert(err0 < 1e-3, "Numerical solution too far from exact one");
    assert(err1 < 1e-3, "Numerical solution too far from exact one");

   annotation (
             experiment(stopTime = 2, Interval = 1e-4, Tolerance = 1e-7));
  end Test3;

end TestSpatialDiscretization;