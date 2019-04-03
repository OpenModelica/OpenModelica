model ParameterCycle
  parameter Boolean bool = true;
  parameter Real var0 = 10;
  parameter Real var1(start=0.1) = if bool then var0 else var0/var2;
  parameter Real var2(start=0.1) = if bool then var0/var1 else var0;
end ParameterCycle;

