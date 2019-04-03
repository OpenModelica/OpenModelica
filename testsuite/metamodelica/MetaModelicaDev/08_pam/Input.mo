package Input

function read
  output Integer outInteger;

  external "C" outInteger = getchar();
  annotation(__OpenModelica_Impure = true);
end read;
end Input;

