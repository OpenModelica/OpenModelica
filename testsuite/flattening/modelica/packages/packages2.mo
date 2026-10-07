// name:     packages2
// keywords: package, declaration
// status:   correct

//
//   Instantiation with packages and extends. Tests special case to avoid infinite recursion.
// When the derived environment for Icons.Library is looked up it is given the FQ name Modelica.Icons.Library
// And that is looked up in top scope. Special case prevents Modelica from being instantiated again and
// cause infinite recursion.

package Modelica
  extends Icons.Library;
  package Constants
    constant Real PI=3.14;
  end Constants;

  package Icons
    package Library
     constant Real L=0.9;
    end Library;
  end Icons;
end Modelica;

model test
  Real x=Modelica.Constants.PI;
end test;


// Result:
// class test
//   Real x = 3.14;
// end test;
// endResult
