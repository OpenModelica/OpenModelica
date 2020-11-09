// name:     RecursiveShort
// keywords: Recursive Short Class Definition
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that compiler does not enter infinite lookup loop in the case
// of recursive short class definition (like type Env = Env.Env; here)
//

model RecursiveShort
  class Env
    type Env = Real;
  end Env;

  class A
    type Env = Env.Env;
    Env e = 1.0;
  end A;

  A a;
end RecursiveShort;

// Result:
// Error processing file: RecursiveShort.mo
// [flattening/modelica/others/RecursiveShort.mo:16:5-16:23:writable] Error: Recursive short class definition of Env in terms of Env.Env.
// Error: Error occurred while flattening model RecursiveShort
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
