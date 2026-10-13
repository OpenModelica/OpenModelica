// name: RedeclareClassConstrainingType1
// keywords:
// status: incorrect
//
// Checks that a redeclared class must be a subtype of the class it redeclares
// when there's no constrainedby clause, see #12957.
//

model BaseFluid
  Real x = 1;
end BaseFluid;

model Fluid1
  extends BaseFluid;
  Real y = 2;
end Fluid1;

model Fluid2
  extends BaseFluid;
  Real z = 3;
end Fluid2;

model Module
  replaceable model Fluid = BaseFluid;
  Fluid fluid;
end Module;

model Stack
  replaceable model Fluid = Fluid1;
  Module module(redeclare model Fluid = Fluid);
end Stack;

model RedeclareClassConstrainingType1
  extends Stack(redeclare model Fluid = Fluid2);
end RedeclareClassConstrainingType1;

// Result:
// Error processing file: RedeclareClassConstrainingType1.mo
// [flattening/modelica/scodeinst/RedeclareClassConstrainingType1.mo:34:27-34:47:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareClassConstrainingType1.mo:29:15-29:35:writable] Error: Redeclaration of class 'Fluid' is not a subtype of the constraining type Fluid1, the element 'y' is missing or has an incompatible type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
