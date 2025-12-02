// name:     ImportInCompositeName2
// keywords: import lookup
// status:   incorrect
//
//

package P
  constant Real PI = 4;
end P;

package P2
  import P.PI;
end P2;

model ImportInCompositeName2
  Real x = P2.PI;
end ImportInCompositeName2;

// Result:
// Error processing file: ImportInCompositeName2.mo
// [flattening/modelica/scodeinst/ImportInCompositeName2.mo:16:3-16:17:writable] Error: Found imported name 'PI' while looking up composite name 'P2.PI'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
