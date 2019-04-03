package ConstantConnect
  model Model1
    Connector1 Out;
    Real Variable2(start=1);
  equation
    Out.parameter1 = Variable2;
  end Model1;

  model Model2
    Connector1 In;
    Real Variable2(start=2);
  equation
    Variable2 = In.parameter1;
  end Model2;

  connector Connector1
   constant Real parameter1=2;
  end Connector1;

  model Model3
    Model1 model1;
    Model2 model2;
  equation
   connect(model1.Out,model2.In);
  end Model3;
end ConstantConnect;
