// name: CevalAcos2
// keywords:
// status: incorrect
//
//

model CevalAcos2
  constant Real r1 = acos(1.3);
end CevalAcos2;

// Result:
// Error processing file: CevalAcos2.mo
// [flattening/modelica/scodeinst/CevalAcos2.mo:8:3-8:31:writable] Error: Argument 1.3 of acos is out of range (-1 <= x <= 1)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
