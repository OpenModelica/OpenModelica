// name: InnerOuterMissing9
// keywords:
// status: incorrect
// cflags: -i=P.InnerOuterMissing9
//
// Checks that only the instance tree is searched when looking for an inner
// element, and not the enclosing scopes of the class being instantiated.
//

package P
  inner Real x;

  model InnerOuterMissing9
    outer Real x;
  end InnerOuterMissing9;
  annotation(__OpenModelica_commandLineOptions="-i=P.InnerOuterMissing9");
end P;

// Result:
// Error processing file: InnerOuterMissing9.mo
// [flattening/modelica/scodeinst/InnerOuterMissing9.mo:14:5-14:17:writable] Error: The model can't be instantiated due to top-level outer element 'x', it may only be used as part of a simulation model.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
