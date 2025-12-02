// name: ConnectorBalance6
// keywords: connector
// status: correct
//
//

record R
  Real x;

  function equalityConstraint
    input R r1;
    input R r2;
    output Real residue[0];
  end equalityConstraint;
end R;

connector C
  Real e;
  flow Real f;
  R r;
end C;

model ConnectorBalance6
  C c;
end ConnectorBalance6;

// Result:
// class ConnectorBalance6
//   Real c.e;
//   Real c.f;
//   Real c.r.x;
// equation
//   c.f = 0.0;
// end ConnectorBalance6;
// endResult
