// name:     ExtendsModWithImport
// keywords: extends import modification bug1255
// status:   correct
//
// Tests extends where a modifier uses an import alias.
//

package Package
  function Func
    input Real IR;
    output Real OR;
  algorithm
    OR := IR;
  end Func;
end Package;

model Model1
  parameter Real param = 0;
end Model1;

model Model2
  import P = Package;
  Model1 m(param = P.Func(1));
end Model2;

model ExtendsModWithImport
  extends Model2;
end ExtendsModWithImport;

// Result:
// function Package.Func
//   input Real IR;
//   output Real OR;
// algorithm
//   OR := IR;
// end Package.Func;
//
// class ExtendsModWithImport
//   parameter Real m.param = 1.0;
// end ExtendsModWithImport;
// endResult
