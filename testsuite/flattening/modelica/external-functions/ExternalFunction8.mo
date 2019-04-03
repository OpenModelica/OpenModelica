// name: ExternalFunction8
// status: incorrect
// teardown_command: rm -f ExternalFunction8_*

class ExternalFunction8
  function fn
    output Real rs[3];
  external "C" rs=my123() annotation(Include="double* my123() {const double my123[3] = {1.0,2.0,3.0}; return (double*) my123;}");
  end fn;

  constant Real rs[3] = fn();
end ExternalFunction8;

// Result:
// Error processing file: ExternalFunction8.mo
// [flattening/modelica/external-functions/ExternalFunction8.mo:6:3-9:9:writable] Error: The lhs (result) of the external function declaration has array type (Real[3]), but this is not allowed in the specification. You need to pass it as an input to the function (preferably also with a size()-expression to avoid out-of-bounds errors in the external call).
// [flattening/modelica/external-functions/ExternalFunction8.mo:11:3-11:29:writable] Error: Class fn not found in scope ExternalFunction8 (looking for a function or record).
// Error: Error occurred while flattening model ExternalFunction8
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
