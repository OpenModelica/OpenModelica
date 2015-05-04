package ErrorFunctionCallNumArgs
function fn
  input Integer i;
  output String s;
algorithm
  s := String(i);
end fn;

function f0
  output String s;
algorithm
  s := fn();
end f0;
function f1
  output String s;
algorithm
  s := fn(1);
end f1;
function f2
  output String s;
algorithm
  s := fn(1,2);
end f2;

end ErrorFunctionCallNumArgs;
