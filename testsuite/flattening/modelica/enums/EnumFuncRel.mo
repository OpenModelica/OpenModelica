// name:     EnumFuncRel
// keywords: 
// status:   incorrect
//
// Checks that a function reference to a function returning an enumeration can't
// be used as an enumeration value.
//

type E = enumeration(one, two, three);

function f
  output E e = E.one;
end f;

function EnumFuncRel
algorithm
  if f == E.one then
  end if;
end EnumFuncRel;

// Result:
// Error processing file: EnumFuncRel.mo
// [flattening/modelica/enums/EnumFuncRel.mo:15:1-19:16:writable] Error: Cannot instantiate EnumFuncRel due to class specialization function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
