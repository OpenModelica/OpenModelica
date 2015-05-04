// name: StaticAssertSuccess
// status: correct
class StaticAssertSuccess
algorithm
  assert(true, "assertion failed :D");
  assert(time < 0.5, "assertion failed :D");
end StaticAssertSuccess;

// Result:
// class StaticAssertSuccess
// algorithm
//   assert(time < 0.5, "assertion failed :D");
// end StaticAssertSuccess;
// endResult
