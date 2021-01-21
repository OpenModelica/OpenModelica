encapsulated package FFI
  import Expression = NFExpression;
  import Type = NFType;

  type ArgSpec = enumeration(
    INPUT,
    OUTPUT,
    LOCAL
  );

  function callFunction
    "Calls the function identified by the given handle (from
     System.lookupFunction) using the given array of arguments and the type of
     the return value. Each argument should also have a corresponding specifier
     in the specs array that tells whether the variable is an input, output, or
     local variable. The return value of the called function is returned, along
     with a list of any output values of the function."
    input Integer fnHandle;
    input array<Expression> args;
    input array<ArgSpec> specs;
    input Type returnType;
    output Expression returnValue;
    output list<Expression> outputArgs;
    external "C" returnValue = FFI_callFunction(fnHandle, args, specs, returnType, outputArgs)
    annotation(Library = "omcruntime");
  end callFunction;

annotation(__OpenModelica_Interface="frontend");
end FFI;
