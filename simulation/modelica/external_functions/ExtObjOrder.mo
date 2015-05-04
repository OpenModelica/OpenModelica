package P
  class Foo
    extends ExternalObject;

    function constructor
      output Foo interface;

      external "C" interface = fooCtor() annotation(Include = "#include \"ExtObjOrder.h\"");
    end constructor;

    function destructor
      input Foo interface;

      external "C" fooDtor(interface) annotation(Include = "#include \"ExtObjOrder.h\"");
    end destructor;
  end Foo;

  class Bar
    extends ExternalObject;

    function constructor
      input Foo param;
      output Bar interface;

      external "C" interface = barCtor(param) annotation(Include = "#include \"ExtObjOrder.h\"");
    end constructor;

    function destructor
      input Bar interface;

      external "C" barDtor(interface) annotation(Include = "#include \"ExtObjOrder.h\"");
    end destructor;
  end Bar;
end P;

model ExtObjOrder
  import P.*;
  Foo foo = Foo();
  Bar bar = Bar(param = foo);
end ExtObjOrder;
