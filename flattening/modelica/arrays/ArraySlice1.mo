// name:     ArraySlice1
// keywords: array
// status:   correct
//
// Simple array slicing.
//

class ArraySlice1
  Real a[4];
equation
  a[{1,3}] = a[{2,4}];
  a[1]=time;
  a[4]=1;
end ArraySlice1;

// Result:
// class ArraySlice1
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// equation
//   a[1] = a[2];
//   a[3] = a[4];
//   a[1] = time;
//   a[4] = 1.0;
// end ArraySlice1;
// endResult
