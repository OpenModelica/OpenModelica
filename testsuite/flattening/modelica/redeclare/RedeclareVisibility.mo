// name:     RedeclareVisibility
// keywords: redeclare, modification, constant
// status:   correct
//
// Checks that it's allowed to redeclare a protected element.
//

model m
  protected replaceable Real x;
end m;

model RedeclareVisibility
  extends m(replaceable Real x = 2.0);
end RedeclareVisibility;

// Result:
// class RedeclareVisibility
//   Real x = 2.0;
// end RedeclareVisibility;
// endResult
