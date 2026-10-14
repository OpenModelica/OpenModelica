// name: IfConnect6
// keywords:
// status: correct
//
//

type R
  extends Real;

  function equalityConstraint
    input R r1;
    input R r2;
    output Real residue[0];
  end equalityConstraint;
end R;

connector C
  R r;
  Real e[3];
  flow Real f[3];
end C;

model M
  C c;
end M;

model IfConnect6
  C c1, c2;
  Boolean b = false;
equation
  Connections.root(c1.r);

  if time > 0 then
    b = Connections.isRoot(c1.r);
  end if;
end IfConnect6;

// Result:
// class IfConnect6
//   Real c1.r;
//   Real c1.e[1];
//   Real c1.e[2];
//   Real c1.e[3];
//   Real c1.f[1];
//   Real c1.f[2];
//   Real c1.f[3];
//   Real c2.r;
//   Real c2.e[1];
//   Real c2.e[2];
//   Real c2.e[3];
//   Real c2.f[1];
//   Real c2.f[2];
//   Real c2.f[3];
//   Boolean b = false;
// equation
//   c1.f[1] = 0.0;
//   c1.f[2] = 0.0;
//   c1.f[3] = 0.0;
//   c2.f[1] = 0.0;
//   c2.f[2] = 0.0;
//   c2.f[3] = 0.0;
//   if time > 0.0 then
//     b = true;
//   end if;
// end IfConnect6;
// endResult
