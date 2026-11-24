model ModelicaIOMatrixAppend
  parameter Real a[1,2](each fixed = false);
  parameter Real b[1,2](each fixed = false);
  Real x(start = 0.0, fixed = true);
protected
  parameter Boolean writtenA(fixed = false);
  parameter Boolean writtenB(fixed = false);
initial algorithm
  writtenA := Modelica.Utilities.Streams.writeRealMatrix("ModelicaIOMatrixAppend.mat", "A", {{1.5, 2.5}}, false, "4");
  writtenB := Modelica.Utilities.Streams.writeRealMatrix("ModelicaIOMatrixAppend.mat", "B", {{3.5, 4.5}}, true, "4");
  a := Modelica.Utilities.Streams.readRealMatrix("ModelicaIOMatrixAppend.mat", "A", 1, 2);
  b := Modelica.Utilities.Streams.readRealMatrix("ModelicaIOMatrixAppend.mat", "B", 1, 2);
equation
  der(x) = sum(a) + 10*sum(b);
end ModelicaIOMatrixAppend;
