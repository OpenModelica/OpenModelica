// name:     Constant8
// keywords: Constant package lookup
// status:   correct
//
// Constants can be looked up in parent scopes, also throug base classs.
//

package A
  package B
   constant Integer N=2;
   model test
     Integer n=N;
     extends test2;
   end test;
   model test2
     Real x;
   end test2;
  end B;
end A;

model Constant8
 extends A.B.test;
end Constant8;

// Result:
// class Constant8
//   Integer n = 2;
//   Real x;
// end Constant8;
// endResult
