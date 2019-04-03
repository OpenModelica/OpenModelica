// name: IfConnect3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model IfConnect3
  Boolean b = true;
  C c1, c2;
equation
  if b then
    connect(c1, c2);
  end if;
end IfConnect3;

// Result:
// Error processing file: IfConnect3.mo
// [flattening/modelica/scodeinst/IfConnect3.mo:18:5-18:20:writable] Error: connect may not be used inside if-equations with non-parametric conditions (found connect(c1, c2)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
