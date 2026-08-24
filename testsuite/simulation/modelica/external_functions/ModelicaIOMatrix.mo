model ModelicaIOMatrix
  parameter Real m[2,3](each fixed = false);
  Real x(start = 0.0, fixed = true);
protected
  parameter Boolean written(fixed = false);
initial algorithm
  written := Modelica.Utilities.Streams.writeRealMatrix("ModelicaIOMatrix.mat", "M", {{1.5,2.5,3.5},{4.5,5.5,6.5}}, false, "4");
  m := Modelica.Utilities.Streams.readRealMatrix("ModelicaIOMatrix.mat", "M", 2, 3);
equation
  der(x) = sum(m);
end ModelicaIOMatrix;
