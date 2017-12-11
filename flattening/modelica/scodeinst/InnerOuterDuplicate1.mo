// name: InnerOuterDuplicate1
// keywords: 
// status: correct
// cflags: -d=newInst
//
// Tests that having duplicate outer elements due to inheritance works
// correctly.
//

model A
  outer Real x;
end A;

model B
  extends A;
  outer Real x;
end B;

model InnerOuterDuplicate1
  inner Real x = 1.0;
  B b;
end InnerOuterDuplicate1;

// Result:
// class InnerOuterDuplicate1
//   Real x = 1.0;
// end InnerOuterDuplicate1;
// endResult
