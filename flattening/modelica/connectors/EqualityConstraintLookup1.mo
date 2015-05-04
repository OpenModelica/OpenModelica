// name:     EqualityConstraintLookup1
// keywords: connect equalityConstraint lookup #2163
// status:   correct
// cflags:   +i=P.M
//
// Checks that the equalityConstraint function of a connector can be found when
// the instantiated model is inside an encapsulated package.
//

package Modelica
  connector Pin
    Real v;
    flow Real i;
    Reference reference;
  end Pin;

  record Reference
    Real gamma;

    function equalityConstraint
      input Reference reference1;
      input Reference reference2;
      output Real residue[0];
    end equalityConstraint;
  end Reference;
end Modelica;

encapsulated package P
  import Modelica;

  model M
    Modelica.Pin pin1, pin2;
  equation
    connect(pin1, pin2);
  end M;
end P;

// Result:
// function Modelica.Reference "Automatically generated record constructor for Modelica.Reference"
//   input Real gamma;
//   output Reference res;
// end Modelica.Reference;
//
// function Modelica.Reference.equalityConstraint
//   input Modelica.Reference reference1;
//   input Modelica.Reference reference2;
//   output Real[0] residue;
// end Modelica.Reference.equalityConstraint;
//
// class P.M
//   Real pin1.v;
//   Real pin1.i;
//   Real pin1.reference.gamma;
//   Real pin2.v;
//   Real pin2.i;
//   Real pin2.reference.gamma;
// equation
//   pin1.i = 0.0;
//   pin2.i = 0.0;
//   (-pin1.i) + (-pin2.i) = 0.0;
//   pin1.reference.gamma = pin2.reference.gamma;
//   pin1.v = pin2.v;
// end P.M;
// endResult
