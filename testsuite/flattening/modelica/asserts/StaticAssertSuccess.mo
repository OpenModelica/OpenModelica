// name: StaticAssertSuccess
// status: correct
class StaticAssertSuccess
algorithm
  assert(true, "assertion failed :D");
  assert(time < 0.5, "assertion failed :D");
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end StaticAssertSuccess;

// Result:
// class StaticAssertSuccess
// algorithm
//   assert(time < 0.5, "assertion failed :D");
// end StaticAssertSuccess;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
