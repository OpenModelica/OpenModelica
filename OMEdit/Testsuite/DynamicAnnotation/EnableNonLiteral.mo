within ;
package EnableNonLiteral
  "Regression model for #15965.

   OpenIPSL components (e.g. OpenIPSL.Interfaces.Generator, OpenIPSL.Electrical.Buses.*)
   display power on the diagram with a DynamicSelect whose dynamic part calls a
   user function, e.g.

     textString = DynamicSelect(\"0.0 MW\", OpenIPSL.NonElectrical.Functions.displayPower(P, \" MW\"))

   The OMEdit FlatModelica evaluator can only reduce builtin operators/functions,
   so a call to a user function evaluates to itself: a non-literal fixed point.
   DynamicAnnotation::evaluate_helper used to re-evaluate such an expression
   recursively until the stack overflowed, and OMEdit hung inside the SIGSEGV
   handler instead of crashing.

   This model reproduces the same non-reducible user-function-call situation
   through the Dialog(enable=...) evaluation path, which the test harness can
   drive without a simulation result file. Evaluating it must terminate."

  function userPredicate
    "Stand-in for a user function the FlatModelica evaluator cannot execute
     (like OpenIPSL.NonElectrical.Functions.displayPower). A call to it stays a
     non-literal expression."
    input Boolean b;
    output Boolean r;
  algorithm
    r := b;
  end userPredicate;

  model MainClass
    parameter Boolean booleanParam = true annotation(choices(checkBox = true));
    // enable is a call to a user function, so it evaluates to the non-literal
    // fixed point userPredicate(true) instead of a Boolean literal.
    parameter Real realParam = 5 annotation(Dialog(enable = userPredicate(booleanParam)));
  end MainClass;

  model ClassWithInstances
    MainClass mainClass annotation(
      Placement(transformation(origin = {10, 10}, extent = {{-10, -10}, {10, 10}})));
  end ClassWithInstances;

  annotation(uses(Modelica(version="4.0.0")));
end EnableNonLiteral;
