// name: CevalRecord6
// keywords:
// status: correct
//

record R
  parameter Real x = 1.0;
  parameter Real y(fixed = false);
  parameter Real z = 3.0;
end R;

model CevalRecord6
  R r1;
  parameter Real x = r1.x annotation(Evaluate=true);
  parameter Real z = r1.z annotation(Evaluate=true);
end CevalRecord6;

// Result:
// class CevalRecord6
//   final parameter Real r1.x = 1.0;
//   parameter Real r1.y(fixed = false);
//   final parameter Real r1.z = 3.0;
//   final parameter Real x = 1.0;
//   final parameter Real z = 3.0;
// end CevalRecord6;
// endResult
