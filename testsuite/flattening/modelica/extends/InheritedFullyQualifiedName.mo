// name:     InheritedFullyQualifiedName
// keywords: #4520
// status:   correct
//
// Tests that fully qualified names in inherited elements aren't corrupted.
//

package P
  function f
    output Real y = 1.0;
  end f;
end P;

package P2
  package P
    model M
      Real x = .P.f();
    end M;
  end P;
end P2;

model InheritedFullyQualifiedName
  extends P2.P.M;
end InheritedFullyQualifiedName;

// Result:
// function P.f
//   output Real y = 1.0;
// end P.f;
//
// class InheritedFullyQualifiedName
//   Real x = 1.0;
// end InheritedFullyQualifiedName;
// endResult
