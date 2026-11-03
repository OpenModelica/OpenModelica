// name: ArrayExtendsUnknown
// keywords: array, inheritance
// status: correct
//
// This test verifies that you can modify an array with unknown dimensions
// in an extends node.

model A
  constant Real[:,:] tableDensity;
  model D
    constant Real[:,:] tableDensity2 = tableDensity;
  end D;
  D d1;
end A;

model B
  extends A(tableDensity = {{1,2},{3,4}});
end B;

model ArrayExtendsUnknown
  extends B;
  D d2;
end ArrayExtendsUnknown;

// Result:
// class ArrayExtendsUnknown
//   constant Real tableDensity[1,1] = 1.0;
//   constant Real tableDensity[1,2] = 2.0;
//   constant Real tableDensity[2,1] = 3.0;
//   constant Real tableDensity[2,2] = 4.0;
//   constant Real d1.tableDensity2[1,1] = 1.0;
//   constant Real d1.tableDensity2[1,2] = 2.0;
//   constant Real d1.tableDensity2[2,1] = 3.0;
//   constant Real d1.tableDensity2[2,2] = 4.0;
//   constant Real d2.tableDensity2[1,1] = 1.0;
//   constant Real d2.tableDensity2[1,2] = 2.0;
//   constant Real d2.tableDensity2[2,1] = 3.0;
//   constant Real d2.tableDensity2[2,2] = 4.0;
// end ArrayExtendsUnknown;
// endResult
