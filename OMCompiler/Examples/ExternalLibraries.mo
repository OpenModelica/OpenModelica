function ExternalFunc1
  input Real x;
  output Real y;
  external y=ExternalFunc1_ext(x) annotation(Library="libExternalFunc1_ext.o",Include="#include \"ExternalFunc1_ext.h\"");
end ExternalFunc1;

function ExternalFunc2
  input Real x;
  output Real y;
  external "C" annotation(Library="libExternalFunc2.a",Include="#include \"ExternalFunc2.h\"");
end ExternalFunc2;


model ExternalLibraries

  Real x(start=1.0),y(start=2.0);
equation
der(x)=-ExternalFunc1(x);
der(y)=-ExternalFunc2(y);
end ExternalLibraries;
