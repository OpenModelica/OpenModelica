uniontype StaticUniontypes

uniontype topNested
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

end topNested;

uniontype regular
  record RR1 end RR1;
end regular;

end StaticUniontypes;

package TestPackage

import StaticUniontypes.topNested.Nested;

function test
 output Integer o = StaticUniontypes.topNested.Nested.foo(4);
end test;

function testMatch
  input Nested n;
  output Integer i;
algorithm
  i := match n
    case fr(__) then 1;
    case _ then 2;
  end match;
end testMatch;

end TestPackage;
