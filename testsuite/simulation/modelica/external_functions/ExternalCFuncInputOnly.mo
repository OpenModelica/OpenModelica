encapsulated package ExternalCFuncInputOnly
  model Component
    parameter Data data(value=true);
  initial equation
    WriteData(data=data);
  end Component;

  record Data
    parameter Boolean value = false;
  end Data;

  function WriteData
    input Data data;
   external"C" WriteDataC(data);
   annotation(Library = "ExternalCFuncInputOnly.o", Include="#include \"ExternalCFuncInputOnly.h\"");
  end WriteData;

end ExternalCFuncInputOnly;
