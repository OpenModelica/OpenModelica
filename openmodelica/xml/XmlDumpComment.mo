model XmlDumpComment
  parameter Real A "test & in xml";
  parameter Real B;
  Real x(start=0) "evaluated to 0 if A < B";
  Real y(start=0);
  Real z;
equation
  x = if (A < B) then 0 else 1;
  y = der(x);
  z = x + y;
end XmlDumpComment;
