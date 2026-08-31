// name: InnerOuter13
// keywords:
// status: correct
//

model A
  model NestedA
    outer Real x;
  end NestedA;

  A.NestedA nestedA;
end A;

model InnerOuter13
  inner Real x = 1;
  A a;
end InnerOuter13;

// Result:
// class InnerOuter13
//   Real x = 1.0;
// end InnerOuter13;
// endResult
