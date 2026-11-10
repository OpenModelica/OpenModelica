// name: ConstantLogicalRelations
// keywords: constant evaluation logical relation operator
// status: correct
//
// Tests constant evaluation of the logical relation operators.
//

model ConstantLogicalRelations
  Boolean b;
equation
  // Equal
  b = false == false;
  b = false == true;
  b = true == false;
  b = true == true;

  // Not equal
  b = false <> false;
  b = false <> true;
  b = true <> false;
  b = true <> true;

  // Greater
  b = false > false;
  b = false > true;
  b = true > false;
  b = true > true;

  // Less
  b = false < false;
  b = false < true;
  b = true < false;
  b = true < true;

  // Less or equal
  b = false <= false;
  b = false <= true;
  b = true <= false;
  b = true <= true;

  // Greater or equal
  b = false >= false;
  b = false >= true;
  b = true >= false;
  b = true >= true;
end ConstantLogicalRelations;

// Result:
// class ConstantLogicalRelations
//   Boolean b;
// equation
//   b = true;
//   b = false;
//   b = false;
//   b = true;
//   b = false;
//   b = true;
//   b = true;
//   b = false;
//   b = false;
//   b = false;
//   b = true;
//   b = false;
//   b = false;
//   b = true;
//   b = false;
//   b = false;
//   b = true;
//   b = true;
//   b = false;
//   b = true;
//   b = true;
//   b = false;
//   b = true;
//   b = true;
// end ConstantLogicalRelations;
// endResult
