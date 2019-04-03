// name:     ArrayReduce2
// keywords: array, sum
// status:   correct
//
// Fixed bug #1153: http://openmodelica.ida.liu.se:8080/cb/issue/1153
//

model A
  parameter Real k = 1;
end A;

model ArrayReduce2
  parameter Integer n = 3;
  A a[n];
  Real y;
equation
  y = sum(a[:].k);
end ArrayReduce2;

// Result:
// class ArrayReduce2
//   parameter Integer n = 3;
//   parameter Real a[1].k = 1.0;
//   parameter Real a[2].k = 1.0;
//   parameter Real a[3].k = 1.0;
//   Real y;
// equation
//   y = a[1].k + a[2].k + a[3].k;
// end ArrayReduce2;
// endResult
