encapsulated package ExternalCFuncInputOnly
  model Component
    parameter Data data(value=true,name= "Component");
  initial equation
    WriteData(data=data);
  end Component;

  record Data
    parameter Boolean value = false;
    parameter String name = "unknown";
  end Data;

  function WriteData
    input Data data;
   external"C" WriteDataC(data);
   annotation(Library = "ExternalCFuncInputOnly.o", Include="#include \"ExternalCFuncInputOnly.h\"");
  end WriteData;

end ExternalCFuncInputOnly;
