// name:     ConstrainType2
// keywords: redeclare component constrainedby
// status:   incorrect
//
// Tests that the constraining class of a replaceable component is implicitly
// the type of the component if no constraining class is defined.
//

class C
  replaceable Real r;
end C;

class ConstrainType2
  extends C;

  redeclare Integer r;
end ConstrainType2;

// Result:
// Error processing file: ConstrainType2.mo
// [ConstrainType2.mo:10:3-10:19:writable] Error: Type Integer is not a subtype of the constraining type Real in redeclaration of component r.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
