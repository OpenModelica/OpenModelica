// name: ClassExtends9
// keywords:
// status: correct
//

partial function f
end f;

package P1
  replaceable function f = .f;
end P1;

package P2
  extends P1;

  redeclare function extends f
    input Real x;
    output Real y = x;
  end f;
end P2;

model ClassExtends9
equation
  P2.f(time);
end ClassExtends9;

// Result:
// function P2.f
//   input Real x;
//   output Real y = x;
// end P2.f;
//
// class ClassExtends9
// equation
//   P2.f(time);
// end ClassExtends9;
// endResult
