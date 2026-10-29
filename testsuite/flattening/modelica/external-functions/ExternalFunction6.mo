// name: ExternalFunction6
// status: correct
// teardown_command: rm -f ExternalFunction6_*

class ExternalFunction6
  function fn
    input Integer i1;
    output Integer i;
  external "C" i=myFn(i1) annotation(Include="#define myFn(X) (2*(X))");
  end fn;

  constant Integer i = fn(2);
  annotation(__OpenModelica_commandLineOptions="-d=gen -d=-newInst");
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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
