encapsulated package NFSCodeFlatten

function flattenCompleteProgram<Path,Program>
  input output Program inProgram;
end flattenCompleteProgram;

function flattenClassInProgram<Path,Program>
  input Path inPath;
  input output Program inProgram;
  output Integer dummy;
end flattenClassInProgram;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeFlatten;
