encapsulated package BlockCallRewrite

function rewriteBlockCall<A>
  input A a,b;
  output A c;
algorithm
  assert(false, getInstanceName());
end rewriteBlockCall;

annotation(__OpenModelica_Interface="backend");
end BlockCallRewrite;
