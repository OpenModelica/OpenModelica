model ExtObjStringParam2

  class MyData
    extends ExternalObject;

    function constructor
      input String fileName;
      input String dummy = "";
      output MyData table;
      external "C" table = constructor(fileName,dummy) annotation(Include = "#include \"ExtObjStringParam.ext.c\"");
    end constructor;

    function destructor
      input MyData table;
      external "C" destructor(table) annotation(Include = "#include \"ExtObjStringParam.ext.c\"");
    end destructor;

  end MyData;

  function testMyData
    input MyData data;
    input Real t;
    output Real r;
  algorithm
    r := 1.5*t;
  end testMyData;

  parameter String DataFile = "sampledata.xml";
  MyData table = MyData(DataFile,"");
  Real r1 = testMyData(table,time);
end ExtObjStringParam2;
