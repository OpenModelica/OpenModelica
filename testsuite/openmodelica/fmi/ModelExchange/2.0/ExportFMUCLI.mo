model ExportFMUCLI
  Real x(start=1, fixed=true);
  parameter Real a=2;
equation
  der(x) = a * x;
end ExportFMUCLI;
