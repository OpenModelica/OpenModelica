// name:     ImportComponent1
// keywords: import
// status:   correct
// cflags:   -d=newInst
//
//

package P
  constant Real pi = 3;
end P;

model ImportComponent1
  import P.pi;
  Real x = pi;
end ImportComponent1;

// Result:
// class ImportComponent1
//   Real x = 3.0;
// end ImportComponent1;
// endResult
