record NestedRecordOutputInner
  Real a;
  Real b[3];
end NestedRecordOutputInner;

record NestedRecordOutputOuter
  NestedRecordOutputInner i;
  Real c;
end NestedRecordOutputOuter;

function nestedRecordOutputF
  input Real x;
  output NestedRecordOutputOuter o;
protected
  Real y;
algorithm
  y := x;
  for k in 1:3 loop
    y := y + x;
  end for;
  o := NestedRecordOutputOuter(i = NestedRecordOutputInner(a = y, b = {x, 2*x, 3*x}), c = 1.0);
end nestedRecordOutputF;

model nestedRecordOutput
  Real t = time;
  NestedRecordOutputOuter o = nestedRecordOutputF(t);
  Real z = o.i.a + o.i.b[1] + o.i.b[3] + o.c;
end nestedRecordOutput;
