// name:     Enumeration5
// keywords: enumeration enum
// status:   incorrect
//
//
//

package P
 type E = enumeration(a,b,c);
 model h
  replaceable type E=enumeration(j, l, k);
  Real hh[E];
 equation
  hh[E.j] = 1.0;
  hh[E.l] = 2.0;
  hh[E.k] = 3.0;
 end h;
end P;

model Enumeration5
   P.h t;
   P.h tt(redeclare type E=enumeration(a1, b2, c1));
end Enumeration5;


// Result:
// Error processing file: Enum5.mo
// [flattening/modelica/enums/Enum5.mo:14:3-14:16:writable] Error: Variable E.j not found in scope P.h$tt.
// [flattening/modelica/enums/Enum5.mo:14:3-14:16:writable] Error: Variable hh[E.j] not found in scope P.h$tt.
// Error: Error occurred while flattening model Enumeration5
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
