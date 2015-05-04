// name:     Record1
// keywords: type
// status:   correct
//

record A
  Real x = 17.0;
end A;

model Record1
  A a(x=18.0);
end Record1;

// Result:
// function A "Automatically generated record constructor for A"
//   input Real x = 17.0;
//   output A res;
// end A;
//
// function A$a "Automatically generated record constructor for A$a"
//   input Real x = 17.0;
//   output A$a res;
// end A$a;
//
// class Record1
//   Real a.x = 18.0;
// end Record1;
// endResult
