// name: BuiltinAttribute1
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute1
  Real r(quantity = "m", unit = "kg", displayUnit = "kg",
    min = -100, max = 100, start = 10, fixed = true, nominal = 1,
    unbounded = true, stateSelect = StateSelect.never);

  Integer i(quantity = "m", min = -100, max = 100, start = 10, fixed = true);
  Boolean b(quantity = "m", start = false, fixed = true);
  String s(quantity = "m", start = "hello", fixed = true);

  type E = enumeration(one, two, three);
  E e(quantity = "m", min = E.two, max = E.three, start = E.two, fixed = false);
end BuiltinAttribute1;


// Result:
// class BuiltinAttribute1
//   Real r(quantity = "m", unit = "kg", displayUnit = "kg", min = -100.0, max = 100.0, start = 10.0, fixed = true, nominal = 1.0, stateSelect = StateSelect.never);
//   Integer i(quantity = "m", min = -100, max = 100, start = 10, fixed = true);
//   Boolean b(quantity = "m", start = false, fixed = true);
//   String s(quantity = "m", start = "hello");
//   enumeration(one, two, three) e(quantity = "m", min = E.two, max = E.three, start = E.two, fixed = false);
// end BuiltinAttribute1;
// endResult
