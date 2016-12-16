// name: ExternalFunction6
// status: correct
// teardown_command: rm -f ExternalFunction6_*
// cflags: -d=gen

class ExternalFunction6
  function fn
    input Integer i1;
    output Integer i;
  external "C" i=myFn(i1) annotation(Include="#define myFn(X) (modelica_integer)(2*(X))");
  end fn;

  constant Integer i = fn(2);
end ExternalFunction6;

// Result:
// function ExternalFunction6.fn
//   input Integer i1;
//   output Integer i;
//
//   external "C" i = myFn(i1);
// end ExternalFunction6.fn;
//
// class ExternalFunction6
//   constant Integer i = 4;
// end ExternalFunction6;
// endResult
