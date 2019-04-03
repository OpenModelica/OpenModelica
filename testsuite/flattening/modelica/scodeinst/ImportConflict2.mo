// name:     ImportConflict2
// keywords: import conflict
// status:   correct
// cflags:   -d=newInst
//
// Checks that conflicting imports are ok as long as they're not used.
//

package P
  model M
    Real x;
  end M;

  model N
    Real x;
  end N;
end P;

model ImportConflict2
  import M = P.M;
  import M = P.N;
  Real x;
end ImportConflict2;

// Result:
// class ImportConflict2
//   Real x;
// end ImportConflict2;
// endResult
