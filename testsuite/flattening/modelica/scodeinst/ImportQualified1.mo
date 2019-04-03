// name:     ImportQualified1
// keywords: qualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that qualified imports work.
//

package P
  model M
    Real x;
  end M;
end P;

model ImportQualified1
  import P.M;
  M m;
end ImportQualified1;

// Result:
// class ImportQualified1
//   Real m.x;
// end ImportQualified1;
// endResult
