// name: MaxArray
// status: correct
// Checks that we can simplify max(array)=>max(scalar1,scalar2)

class MaxArray
  type E = enumeration(A,B,C);
  Real r1 = max({time});
  Real r2 = max({time*2,time});
  E e1 = max({E.A});
  E e2 = max({E.A,E.C});
end MaxArray;

// Result:
// class MaxArray
//   Real r1 = time;
//   Real r2 = max({time * 2.0, time});
//   enumeration(A, B, C) e1 = E.A;
//   enumeration(A, B, C) e2 = E.C;
// end MaxArray;
// [flattening/modelica/built-in-functions/MaxArray.mo:7:3-7:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/built-in-functions/MaxArray.mo:8:3-8:31:writable] Warning: Components are deprecated in class.
// [flattening/modelica/built-in-functions/MaxArray.mo:9:3-9:20:writable] Warning: Components are deprecated in class.
// [flattening/modelica/built-in-functions/MaxArray.mo:10:3-10:24:writable] Warning: Components are deprecated in class.
//
// endResult
