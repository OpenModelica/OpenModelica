// name: ConditionInvalidBinding2
// keywords:
// status: correct
//

model ConditionInvalidBinding2
  Real x = "string" if false;
end ConditionInvalidBinding2;

// Result:
// class ConditionInvalidBinding2
// end ConditionInvalidBinding2;
// endResult
