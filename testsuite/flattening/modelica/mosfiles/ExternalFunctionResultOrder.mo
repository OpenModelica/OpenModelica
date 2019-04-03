package ExternalFunctionResultOrder

function c1234
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "C" targ4 = f1234(targ1,targ2,targ3) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end c1234;

function c2341
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "C" targ3 = f1234(targ4,targ1,targ2) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end c2341;

function c1243
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "C" targ3 = f1234(targ1,targ2,targ4) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end c1243;

function c4321
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "C" targ1 = f1234(targ4,targ3,targ2) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end c4321;

function f1234
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "FORTRAN 77" targ4 = f1234(targ1,targ2,targ3) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end f1234;

function f2341
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "FORTRAN 77" targ3 = f1234(targ4,targ1,targ2) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end f2341;

function f1243
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "FORTRAN 77" targ3 = f1234(targ1,targ2,targ4) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end f1243;

function f4321
  output Integer targ1;
  output Integer targ2;
  output Integer targ3;
  output Integer targ4;
external "FORTRAN 77" targ1 = f1234(targ4,targ3,targ2) annotation(Include = "#include \"ext_ExternalFunctionResultOrder.c\"");
end f4321;

end ExternalFunctionResultOrder;
