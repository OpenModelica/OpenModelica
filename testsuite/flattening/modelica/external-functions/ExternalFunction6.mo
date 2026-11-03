model ExternalFunction6
  function fn
    input Integer i1;
    output Integer i;
  external "C" i=myFn(i1) annotation(Include="#define myFn(X) (2*(X))");
  end fn;

  Integer i = fn(2);
end ExternalFunction6;
