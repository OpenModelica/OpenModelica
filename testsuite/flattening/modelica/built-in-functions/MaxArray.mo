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
//   Real r2 = max(2.0 * time, time);
//   enumeration(A, B, C) e1 = MaxArray.E.A;
//   enumeration(A, B, C) e2 = MaxArray.E.C;
// end MaxArray;
// endResult
