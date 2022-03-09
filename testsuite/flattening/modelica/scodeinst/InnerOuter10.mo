// name: InnerOuter10
// keywords:
// status: correct
// cflags: -d=newInst
//

model InnerOuter10
  connector R = Real;
  inner R r;

  model B
    outer R r;
  end B;

  B b;
end InnerOuter10;

// Result:
// class InnerOuter10
//   Real r;
// end InnerOuter10;
// endResult
