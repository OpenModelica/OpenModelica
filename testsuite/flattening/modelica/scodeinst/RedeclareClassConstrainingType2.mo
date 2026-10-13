// name: RedeclareClassConstrainingType2
// keywords:
// status: correct
//
// Checks that a class can be redeclared with any subtype of the constraining
// class, also when it's not a subtype of the redeclared class, see #12957.
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
  replaceable model Fluid = Fluid1 constrainedby BaseFluid;
  Module module(redeclare model Fluid = Fluid);
end Stack;

model RedeclareClassConstrainingType2
  extends Stack(redeclare model Fluid = Fluid2);
end RedeclareClassConstrainingType2;

// Result:
// class RedeclareClassConstrainingType2
//   Real module.fluid.x = 1.0;
//   Real module.fluid.z = 3.0;
// end RedeclareClassConstrainingType2;
// endResult
