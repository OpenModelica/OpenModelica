// name:     ImportUnqualified1
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that unqualified imports work.
//

package P
  model M
    Real x;
  end M;
end P;

model ImportUnqualified1
  import P.*;
  M m;
end ImportUnqualified1;

// Result:
// class ImportUnqualified1
//   Real m.x;
// end ImportUnqualified1;
// endResult
