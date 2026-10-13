// name: RedeclareClassConstrainingType3
// keywords:
// status: incorrect
//
// Checks that a redeclared class must be a subtype of the constraining class
// given by a constrainedby clause.
//

model BaseFluid
  Real x = 1;
end BaseFluid;

model Fluid1
  extends BaseFluid;
  Real y = 2;
end Fluid1;

model Stack
  replaceable model Fluid = Fluid1 constrainedby BaseFluid;
  Fluid fluid;
end Stack;

model RedeclareClassConstrainingType3
  extends Stack;

  redeclare model Fluid
    Real y = 2;
  end Fluid;
end RedeclareClassConstrainingType3;

// Result:
// Error processing file: RedeclareClassConstrainingType3.mo
// [flattening/modelica/scodeinst/RedeclareClassConstrainingType3.mo:26:13-28:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareClassConstrainingType3.mo:19:15-19:36:writable] Error: Redeclaration of class 'Fluid' is not a subtype of the constraining type BaseFluid, the element 'x' is missing or has an incompatible type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
