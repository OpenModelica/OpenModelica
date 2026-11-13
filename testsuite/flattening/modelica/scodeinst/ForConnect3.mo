// name: ForConnect3
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

model ForConnect3
  C c1[3];
equation
  for i in 1:(if Connections.isRoot(c1[1].r) then 2 else 3) loop
    connect(c1[i], c1[i+1]);
  end for;
end ForConnect3;

// Result:
// Error processing file: ForConnect3.mo
// [flattening/modelica/scodeinst/ForConnect3.mo:31:5-31:28:writable] Error: connect may not be used inside if- or for-equations with non-evaluable conditions or iteration ranges.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
