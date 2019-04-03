// name: Comment1
// keywords:
// status: correct
// cflags: -d=newInst
//

model Comment1 "class comment"
  Real x "component comment";
equation
  x = 1 "equation comment";
algorithm
  x := 1 "statement comment";
end Comment1;

// Result:
// class Comment1 "class comment"
//   Real x "component comment";
// equation
//   x = 1.0 "equation comment";
// algorithm
//   x := 1.0 "statement comment";
// end Comment1;
// endResult
