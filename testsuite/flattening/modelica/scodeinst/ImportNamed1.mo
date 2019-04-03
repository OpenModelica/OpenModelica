// name:     ImportNamed1
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that named imports without renaming works.
//

package P
  model M
    Real x;
  end M;
end P;

model ImportNamed1
  import M = P.M;
  M m;
end ImportNamed1;

// Result:
// class ImportNamed1
//   Real m.x;
// end ImportNamed1;
// endResult
