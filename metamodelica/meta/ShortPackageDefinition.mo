// status: correct
// cflags: +g=MetaModelica

package PKG

function f
  output Integer result;
algorithm
  result := 1;
end f;

end PKG;

package PKG2

package P = PKG;
// This also fails:
// import P = PKG;

function test
algorithm
  P.f();
end test;

end PKG2;

model ShortPackageDefinition
  function test
  end test;
algorithm
  PKG2.test();
  test();
end ShortPackageDefinition;

// Result:
// function PKG2.P.f
//   output Integer result;
// algorithm
//   result := 1;
// end PKG2.P.f;
//
// function PKG2.test
// algorithm
//   PKG2.P.f();
// end PKG2.test;
//
// function ShortPackageDefinition.test
// end ShortPackageDefinition.test;
//
// class ShortPackageDefinition
// algorithm
//   PKG2.test();
//   ShortPackageDefinition.test();
// end ShortPackageDefinition;
// endResult
