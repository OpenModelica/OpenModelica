// name:     Extends2
// keywords: extends
// status:   correct
//
// Testing extends clauses, and encapsulated models. MathCore bug #372

package B

   type W=Real;
end B;

model A
  Adapter adapter;

protected
 encapsulated model Adapter
   import B.W;
     W x;
  end Adapter;
end A;

model test2
  extends A;
end test2;

// Result:
// class test2
//   Real adapter.x;
// end test2;
// endResult
