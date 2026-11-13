// name:     Constant7
// keywords: Constant package lookup
// status:   correct
//
// Constants can be looked up in parent scopes.
//

package A
  constant Real C1=1;
  model test
    A.B.B2 b(C=C1);
  end test;
  package B
    model B2
      parameter Real C;
    end B2;
  end B;

end A;

model Constant7
  A.test t;
end Constant7;
// Result:
// class Constant7
//   parameter Real t.b.C = 1.0;
// end Constant7;
// endResult
