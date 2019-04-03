// name:     Extends10
// keywords: extends
// status:   correct
//
// Testing that imports are handled properly when extending.
//

class M

class Poly
  constant Real x = 1.0;
end Poly;

class A

import P = M.Poly;

function f
  input Real r;
  output Real out;
algorithm
  out := P.x;
end f;

Real x = f(time);

end A;

end M;

class Extends10
  extends M.A;
end Extends10;

// Result:
// function Extends10.f
//   input Real r;
//   output Real out;
// algorithm
//   out := 1.0;
// end Extends10.f;
//
// class Extends10
//   Real x = Extends10.f(time);
// end Extends10;
// endResult
