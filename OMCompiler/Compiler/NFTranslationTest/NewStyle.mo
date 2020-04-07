package StaticUniontypes

uniontype Nested
function foo
  input Real x;
  output Real y;
algorithm
  y := x - 3;
end foo;

record fR
end fR;

record hR
end hR;

end Nested;

uniontype regular
  record RR1 end RR1;
end regular;

end StaticUniontypes;

package TestPackage

import StaticUniontypes;

function test
 output Integer o = StaticUniontypes.Nested.foo(4);
end test;

end TestPackage;
