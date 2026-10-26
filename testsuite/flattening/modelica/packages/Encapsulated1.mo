// name:     Encapsulated1
// keywords: encapsulated
// status:   correct
//
// Demonstrating correct use of import.

encapsulated package A
  package B
    model C
      Real x;
    end C;
  end B;
  encapsulated package B1
    import A.*;
    model C2=B.C(x=2);
  end B1;
end A;


encapsulated model Encapsulated1
  import A.*;
  import A.B1.C2;
  B.C c(x=1);
end Encapsulated1;

// Result:
// class Encapsulated1
//   Real c.x = 1.0;
// end Encapsulated1;
// endResult
