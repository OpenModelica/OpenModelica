// name: BuiltinAttribute20
// keywords:
// status: correct
//

model BuiltinAttribute20
  Real x[3](each start);
end BuiltinAttribute20;

// Result:
// class BuiltinAttribute20
//   Real x[1];
//   Real x[2];
//   Real x[3];
// end BuiltinAttribute20;
// endResult
