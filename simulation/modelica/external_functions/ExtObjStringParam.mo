model ExtObjStringParam

  class MyData
    extends ExternalObject;

    function constructor
      input String fileName;
      input String dummy;
      output MyData table;
      external "C" table = constructor(fileName,dummy) annotation(Library = "ExtObjStringParam.ext.o", Include = "#include \"ExtObjStringParam.ext.h\"");
    end constructor;

    function destructor
      input MyData table;
      external "C" destructor(table) annotation(Library = "ExtObjStringParam.ext.o", Include = "#include \"ExtObjStringParam.ext.h\"");
    end destructor;

  end MyData;

  function dummy
    output String str;
  algorithm
    str := "";
    for i in 1:100 loop
      str := str + "1234567890123456789012345678901234567890";
    end for;
  end dummy;

  parameter String DataFile = "sampledata.xml";
  parameter Boolean tableOnFile = true;
  MyData table[100]= fill(MyData(if tableOnFile then DataFile else "NoName", dummy()), 100);

end ExtObjStringParam;
