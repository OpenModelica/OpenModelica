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
// [flattening/modelica/enums/EnumFuncRel.mo:17:3-18:9:writable] Error: Cannot resolve type of expression f == E.one. The operands have types .f<function>() => #enumeration(one, two, three), enumeration(one, two, three) in component <NO COMPONENT>.
// Error: Error occurred while flattening model EnumFuncRel
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
