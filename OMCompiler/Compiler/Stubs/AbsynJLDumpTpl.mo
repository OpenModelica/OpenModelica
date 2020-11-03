encapsulated package AbsynJLDumpTpl

function dump<Text,Program>
  input Text txt;
  input Program a_program;

  output Text out_txt;
algorithm
  out_txt := txt;
end dump;

annotation(__OpenModelica_Interface="frontend");
end AbsynJLDumpTpl;
