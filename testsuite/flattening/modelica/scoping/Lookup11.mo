// name:     Lookup11
// keywords: scoping, fully qualified, cref, #2738
// status:   correct
//
// Checks that the elaboration respects the full qualification on crefs.
//

package P
  constant Real k = 1;

  model M
    parameter Real k = .P.k;
  end M;

  model P
    M c1;
  end P;
end P;

model Lookup11
  P.P p;
end Lookup11;

// Result:
// class Lookup11
//   parameter Real p.c1.k = 1.0;
// end Lookup11;
// endResult
