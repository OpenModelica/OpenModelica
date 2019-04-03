// cflags: +d=nogen
// status: correct

model Identity4

function f
  input Integer is[3];
  input Integer s;
  output Integer o1[3,3] = diagonal(is);
  output Integer o2[s,s] = identity(s);
end f;

  Integer[3,3] o1,o2;
algorithm
  (o1,o2) := f({1,2,3},3);
end Identity4;

// Result:
// function Identity4.f
//   input Integer[3] is;
//   input Integer s;
//   output Integer[3, 3] o1 = {{is[1], 0, 0}, {0, is[2], 0}, {0, 0, is[3]}};
//   output Integer[s, s] o2 = identity(s);
// end Identity4.f;
//
// class Identity4
//   Integer o1[1,1];
//   Integer o1[1,2];
//   Integer o1[1,3];
//   Integer o1[2,1];
//   Integer o1[2,2];
//   Integer o1[2,3];
//   Integer o1[3,1];
//   Integer o1[3,2];
//   Integer o1[3,3];
//   Integer o2[1,1];
//   Integer o2[1,2];
//   Integer o2[1,3];
//   Integer o2[2,1];
//   Integer o2[2,2];
//   Integer o2[2,3];
//   Integer o2[3,1];
//   Integer o2[3,2];
//   Integer o2[3,3];
// algorithm
//   o1 := {{1, 0, 0}, {0, 2, 0}, {0, 0, 3}};
//   o2 := {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
// end Identity4;
// endResult
