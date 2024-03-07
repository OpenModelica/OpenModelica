model XmlDumpComment
  parameter Real A = 0 "test & in xml";
  parameter Real B = 1;
  Real x(start=0) "evaluated to 0 if A < B";
  Real y(start=0);
  Real z;
equation
  x = if (A < B) then 0 else 1;
  y = der(x);
  z = x + y;
end XmlDumpComment;
