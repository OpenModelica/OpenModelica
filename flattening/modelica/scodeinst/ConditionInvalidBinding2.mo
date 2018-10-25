// name: ConditionInvalidBinding2
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConditionInvalidBinding2
  Real x = "string" if false;
end ConditionInvalidBinding2;

// Result:
// class ConditionInvalidBinding2
// end ConditionInvalidBinding2;
// endResult
