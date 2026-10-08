within ;
package EnableExternalConstant
  "Regression model for #16270.

   An annotation expression may use a constant that is declared outside the model,
   e.g. Modelica.Constants.eps or a constant in another package of the same library.
   The instance API gives such a name to OMEdit as a fully qualified cref, and it is
   neither an element of the model nor a variable in the result file, so the OMEdit
   evaluator used to give up on the whole expression. A DynamicSelect on an icon then
   kept showing its static part, and a Dialog(enable=...) kept its default.

   The Dialog(enable=...) path is used here because the test harness can drive it
   without a simulation result file."

  package Constants
    constant Boolean disabled = false;
    constant Real threshold = 0.5;
  end Constants;

  model MainClass
    parameter Real constantParam = 5 annotation(Dialog(enable = EnableExternalConstant.Constants.disabled));
    parameter Real comparedParam = 5 annotation(Dialog(enable = EnableExternalConstant.Constants.threshold > 1));
    parameter Real enabledParam = 5 annotation(Dialog(enable = EnableExternalConstant.Constants.threshold < 1));
    parameter Real mslParam = 5 annotation(Dialog(enable = Modelica.Constants.eps > 1));
  end MainClass;

  model ClassWithInstances
    MainClass mainClass annotation(
      Placement(transformation(origin = {10, 10}, extent = {{-10, -10}, {10, 10}})));
  end ClassWithInstances;

  annotation(uses(Modelica(version="4.0.0")));
end EnableExternalConstant;
