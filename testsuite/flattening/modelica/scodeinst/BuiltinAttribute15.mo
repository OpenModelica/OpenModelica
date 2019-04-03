// name: BuiltinAttribute15
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute15
  type MyReal = Real(start = x);
  constant MyReal x = 1.0;
end BuiltinAttribute15;

// Result:
// class BuiltinAttribute15
//   constant Real x(start = 1.0) = 1.0;
// end BuiltinAttribute15;
// endResult
