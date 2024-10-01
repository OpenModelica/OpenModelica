// name: ConstrainingClassFunc1
// keywords:
// status: correct
//

package P
  partial function f
    input Real a;
    input Real b;
    output Real c;
  end f;

  function fun
    extends f;
  algorithm
    c := a + b;
  end fun;

  replaceable function func = fun constrainedby f(b = 1);
end P;

model ConstrainingClassFunc1
 parameter Real x = P.func(15);
end ConstrainingClassFunc1;

// Result:
// class ConstrainingClassFunc1
//   parameter Real x = 16.0;
// end ConstrainingClassFunc1;
// endResult
