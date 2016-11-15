// name:     ImportNamed2
// keywords: named import
// status:   correct
// cflags:   -d=newInst
//
// Checks that named imports with renaming works.
//

package P
  model M
    Real x;
  end M;
end P;

model ImportNamed2
  import N = P.M;
  N m;
end ImportNamed2;

// Result:
// class ImportNamed2
//   Real m.x;
// end ImportNamed2;
// endResult
