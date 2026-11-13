// name: Comment1
// keywords: comment
// status: correct
//
// This file tests //-style single-line comments
//

// This is a comment
model Comment1 // Another comment
  Real x; //
equation
  //
  x = 2;
  // Comment
end Comment1; //

// Comment again...

// Result:
// class Comment1
//   Real x;
// equation
//   x = 2.0;
// end Comment1;
// endResult
