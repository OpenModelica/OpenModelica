function Trans
  input Real[:,:] x;
  output Real[size(x,2), size(x,1)] y;
  external "C" annotation(Library="libFunc.a",Include="#include \"Func.h\"");
end Trans;

model tt
  Real[2,3] x = [1,2,3;4,5,6];
  Real[3,2] z,y;
equation
  z = Trans(x);
  y = Trans(x);
end tt;
