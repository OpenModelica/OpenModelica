// name: ArrayAssignWholeDim
// keywords: slice array assign
// status: correct
//
// Fix for bugs in c_runtime/real_array.c indexed_assign_real_array() and index_real_array()
// Should be moved to mosfiles to ensure c-runtime invocation

model ArrayAssignWholeDim
  function GetA
       input Real[:] x;
       output Real[size(x,1),4] a;
     algorithm
        a[:,1] := x; //just to trigger compilation and usage of the indexed_assign_real_array()
        a[1,:] := { 10, 20, 30, 40 }; //here was the bug in indexed_assign_real_array()
        a[size(x,1), :] := { 0.1, 0.2, 0.3, 0.4 }; //and here
        a[2:3,2] := x[2:3];  //and another one in index_real_array()
  end GetA;
  constant Real X[:] = {1,2,3,4,5};
  constant Real A[:,4] = GetA(X);
end ArrayAssignWholeDim;

// Result:
// function ArrayAssignWholeDim.GetA
//   input Real[:] x;
//   output Real[size(x, 1), 4] a;
// algorithm
//   a[:,1] := x;
//   a[1,:] := {10.0, 20.0, 30.0, 40.0};
//   a[size(x, 1),:] := {0.1, 0.2, 0.3, 0.4};
//   a[{2, 3},2] := {x[2], x[3]};
// end ArrayAssignWholeDim.GetA;
//
// class ArrayAssignWholeDim
//   constant Real X[1] = 1.0;
//   constant Real X[2] = 2.0;
//   constant Real X[3] = 3.0;
//   constant Real X[4] = 4.0;
//   constant Real X[5] = 5.0;
//   constant Real A[1,1] = 10.0;
//   constant Real A[1,2] = 20.0;
//   constant Real A[1,3] = 30.0;
//   constant Real A[1,4] = 40.0;
//   constant Real A[2,1] = 2.0;
//   constant Real A[2,2] = 2.0;
//   constant Real A[2,3] = 0.0;
//   constant Real A[2,4] = 0.0;
//   constant Real A[3,1] = 3.0;
//   constant Real A[3,2] = 3.0;
//   constant Real A[3,3] = 0.0;
//   constant Real A[3,4] = 0.0;
//   constant Real A[4,1] = 4.0;
//   constant Real A[4,2] = 0.0;
//   constant Real A[4,3] = 0.0;
//   constant Real A[4,4] = 0.0;
//   constant Real A[5,1] = 0.1;
//   constant Real A[5,2] = 0.2;
//   constant Real A[5,3] = 0.3;
//   constant Real A[5,4] = 0.4;
// end ArrayAssignWholeDim;
// endResult
