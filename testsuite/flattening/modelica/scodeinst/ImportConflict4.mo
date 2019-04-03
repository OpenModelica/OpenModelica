// name:     ImportConflict4
// keywords: import conflict
// status:   correct
// cflags:   -d=newInst
//
// Checks that importing the same name from multiple sources is ok as long as
// that name isn't used.
//

package P
  package P1
    model M
      Real x;
    end M;
  end P1;

  package P2
    model M
      Real x;
    end M;
  end P2;
end P;

model ImportConflict4
  import P.P1.*;
  import P.P2.*;
  Real x;
end ImportConflict4;

// Result:
// class ImportConflict4
//   Real x;
// end ImportConflict4;
// endResult
