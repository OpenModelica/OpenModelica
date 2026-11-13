// name: IfConnect5
// keywords:
// status: incorrect
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

model IfConnect5
  C c1, c2;
equation
  if Connections.isRoot(c1.r) then
    Connections.root(c1.r);
  end if;
end IfConnect5;

// Result:
// Error processing file: IfConnect5.mo
// [flattening/modelica/scodeinst/IfConnect5.mo:31:5-31:27:writable] Error: Connections.root may not be used inside if- or for-equations with non-evaluable conditions or iteration ranges.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
