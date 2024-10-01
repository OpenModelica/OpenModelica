// name: InnerOuter10
// keywords:
// status: correct
//

model InnerOuter10
  connector R = input Real;
  inner R r;

  model B
    outer R r;
  end B;

  B b;
end InnerOuter10;

// Result:
// class InnerOuter10
//   input Real r;
// end InnerOuter10;
// endResult
