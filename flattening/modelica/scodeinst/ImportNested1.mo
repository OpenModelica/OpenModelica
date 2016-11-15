// name:     ImportNested1
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that named imports can be 'nested'.
//

package A
  model M Real x; end M;
end A;

package B
  import A;
end B;

model ImportNested1
  import B;
  B.A.M m;
end ImportNested1;

// Result:
// class ImportNested1
//   Real m.x;
// end ImportNested1;
// endResult
