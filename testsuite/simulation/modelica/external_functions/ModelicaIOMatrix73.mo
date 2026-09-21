model ModelicaIOMatrix73
  parameter Real m[2,3](each fixed = false);
  parameter Real n[1,2](each fixed = false);
  parameter Integer dims[2](each fixed = false);
  Real x(start = 0.0, fixed = true);
protected
  parameter Boolean written[2](each fixed = false);
initial algorithm
  written[1] := Modelica.Utilities.Streams.writeRealMatrix("ModelicaIOMatrix73.mat", "M", {{1.5,2.5,3.5},{4.5,5.5,6.5}}, false, "7.3");
  written[2] := Modelica.Utilities.Streams.writeRealMatrix("ModelicaIOMatrix73.mat", "N", {{-1.5,0.25}}, true, "7.3");
  dims := Modelica.Utilities.Streams.readMatrixSize("ModelicaIOMatrix73.mat", "M");
  m := Modelica.Utilities.Streams.readRealMatrix("ModelicaIOMatrix73.mat", "M", 2, 3);
  n := Modelica.Utilities.Streams.readRealMatrix("ModelicaIOMatrix73.mat", "N", 1, 2);
equation
  der(x) = sum(m) + sum(n);
end ModelicaIOMatrix73;
