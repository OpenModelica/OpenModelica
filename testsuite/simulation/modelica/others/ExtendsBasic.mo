class ExtendsBasic

type TypeString "Icon for a String type"
  extends String;
  annotation(X=Y);
end TypeString;

type TypeReal "Icon for a Real type"
  extends Real;
  annotation(X=Y);
end TypeReal;

function extendsString
  input TypeString strIn;
  output TypeString strOut;
algorithm
  strOut := "Result: " + strIn;
end extendsString;

function extendsReal
  input TypeReal realIn;
  output TypeReal realOut;
algorithm
  realOut := cos(realIn);
end extendsReal;

TypeReal r;
TypeString s;
equation
  r = extendsReal(time);
  s = extendsString("abc");
end ExtendsBasic;
