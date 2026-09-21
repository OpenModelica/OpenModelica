// name: RecordBinding17
// keywords:
// status: correct
//

record R
  Real x(start = 0);
  Integer y(start = 0);
end R;

function f
  output R r;
algorithm
  r.x := 0;
end f;

model RecordBinding17
  final parameter R m = f() annotation(Evaluate = true);
  final parameter Integer m_type = if m.y > 0.5 then -1 else 1;
end RecordBinding17;

// Result:
// class RecordBinding17
//   final parameter Real m.x(start = 0.0) = 0.0;
//   final parameter Integer m.y(start = 0) = 0;
//   final parameter Integer m_type = 1;
// end RecordBinding17;
// [flattening/modelica/scodeinst/RecordBinding17.mo:12:3-12:13:writable] Warning: Output parameter r.y was not assigned a value
//
// endResult
