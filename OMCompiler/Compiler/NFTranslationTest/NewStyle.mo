uniontype StaticUniontypes
protected
  record TOPDUMMY
  end TOPDUMMY;
public
//Basic arithmetic operators
  type Op = enumeration(
    ADD               "+",
    SUB               "-",
    MUL               "*",
    DIV               "/",
    POW               "^"
  );

uniontype topNested
uniontype Nested
function foo
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
end testMatch;

end TestPackage;

uniontype WeirdUniontype
  import TestPackage;
  function f1
  end f1;
  function f2
  end f2;
end WeirdUniontype;
