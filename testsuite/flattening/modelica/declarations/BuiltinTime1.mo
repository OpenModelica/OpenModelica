// name:     BuiltinTime1
// keywords: time builtin
// status:   correct
// cflags: -d=-newInst
//
// Checks that the builtin variable time can be used.
//

model BuiltinTime1
  Real x = time;
end BuiltinTime1;

// Result:
// class BuiltinTime1
//   Real x = time;
// end BuiltinTime1;
// endResult
