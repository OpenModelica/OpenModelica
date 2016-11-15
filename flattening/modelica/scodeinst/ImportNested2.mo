// name:     ImportNested2
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that unqualified imports can be 'nested'.
//

package A
  model M Real x; end M;
end A;

package B
  import A.*;
end B;

model ImportNested2
  import B.*;
  B.M m;
end ImportNested2;

// Result:
// class ImportNested2
//   Real m.x;
// end ImportNested2;
// endResult
