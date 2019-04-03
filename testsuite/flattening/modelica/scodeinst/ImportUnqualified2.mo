// name:     ImportUnqualified2
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that unqualified imports work.
//

package P
  constant Real x = 2;
end P;

model ImportUnqualified2
  import P.*;
  Real y = x;
end ImportUnqualified2;

// Result:
// class ImportUnqualified2
//   Real y = 2.0;
// end ImportUnqualified2;
// endResult
