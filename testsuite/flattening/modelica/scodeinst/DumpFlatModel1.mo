// name: DumpFlatModel1
// keywords:
// status: correct
// cflags: -d=newInst --dumpFlatModel
//

model A
  Real x[3] = {1, 2, 3};
  Real y[3];
equation
  for i loop
    y[i] = x[i];
  end for;
end A;

model DumpFlatModel1
  A a1;
  A a2(x = {4, 5, 6});
algorithm
  a1.x := ones(size(a1.x, 1));
end DumpFlatModel1;

// Result:
// ########################################
// flatten
// ########################################
//
// class DumpFlatModel1
//   Real[3] a1.x;
//   Real[3] a1.y;
//   Real[3] a2.x;
//   Real[3] a2.y;
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := fill(1.0, 3);
// end DumpFlatModel1;
//
// ########################################
// connections
// ########################################
//
// class DumpFlatModel1
//   Real[3] a1.x;
//   Real[3] a1.y;
//   Real[3] a2.x;
//   Real[3] a2.y;
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := fill(1.0, 3);
// end DumpFlatModel1;
//
// ########################################
// eval
// ########################################
//
// class DumpFlatModel1
//   Real[3] a1.x;
//   Real[3] a1.y;
//   Real[3] a2.x;
//   Real[3] a2.y;
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := fill(1.0, 3);
// end DumpFlatModel1;
//
// ########################################
// simplify
// ########################################
//
// class DumpFlatModel1
//   Real[3] a1.x;
//   Real[3] a1.y;
//   Real[3] a2.x;
//   Real[3] a2.y;
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := {1.0, 1.0, 1.0};
// end DumpFlatModel1;
//
// ########################################
// scalarize
// ########################################
//
// class DumpFlatModel1
//   Real a1.x[1];
//   Real a1.x[2];
//   Real a1.x[3];
//   Real a1.y[1];
//   Real a1.y[2];
//   Real a1.y[3];
//   Real a2.x[1];
//   Real a2.x[2];
//   Real a2.x[3];
//   Real a2.y[1];
//   Real a2.y[2];
//   Real a2.y[3];
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := {1.0, 1.0, 1.0};
// end DumpFlatModel1;
//
// class DumpFlatModel1
//   Real a1.x[1];
//   Real a1.x[2];
//   Real a1.x[3];
//   Real a1.y[1];
//   Real a1.y[2];
//   Real a1.y[3];
//   Real a2.x[1];
//   Real a2.x[2];
//   Real a2.x[3];
//   Real a2.y[1];
//   Real a2.y[2];
//   Real a2.y[3];
// equation
//   a1.x = {1.0, 2.0, 3.0};
//   a1.y[1] = a1.x[1];
//   a1.y[2] = a1.x[2];
//   a1.y[3] = a1.x[3];
//   a2.x = {4.0, 5.0, 6.0};
//   a2.y[1] = a2.x[1];
//   a2.y[2] = a2.x[2];
//   a2.y[3] = a2.x[3];
// algorithm
//   a1.x := {1.0, 1.0, 1.0};
// end DumpFlatModel1;
// endResult
