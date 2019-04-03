// name:     ForceAndTorque.mo
// keywords: component array addressing
// status:   correct
//
//  Verify component array addressing
//  adrpo: This tests for bug that generated things like:
//            force.y[1] = forceAndTorque.force[1];
//         instead of correct:
//            force[1].y = forceAndTorque.force[1];
//


package Internal

connector RealInput = input Real "'input Real' as connector";
connector RealOutput = output Real "'output Real' as connector";

model ForceAndTorque "Force and torque acting between two frames"
  model BasicForce "Force acting between two frames, defined by 3 input signals"
    RealInput force[3](each final quantity="Force", each final unit = "N") "x-, y-, z-coordinates of force";
  end BasicForce;

  RealInput force[3](each final quantity="Force", each final unit = "N") "x-, y-, z-coordinates of force";

  BasicForce basicForce;
equation
  connect(basicForce.force, force);
end ForceAndTorque;

partial block SO "Single Output continuous control block"
  RealOutput y "Connector of Real output signal";
end SO;

block Constant "Generate constant signal of type Real"
 parameter Real k(start=1) "Constant output value";
 extends SO;
equation
 y = k;
end Constant;

end Internal;

model ForceAndTorque
  Internal.ForceAndTorque forceAndTorque;
  Internal.Constant force[3](k={0,1000,0});
equation
  connect(force.y, forceAndTorque.force);
end ForceAndTorque;

// Result:
// class ForceAndTorque
//   Real forceAndTorque.force[1](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real forceAndTorque.force[2](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real forceAndTorque.force[3](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real forceAndTorque.basicForce.force[1](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real forceAndTorque.basicForce.force[2](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real forceAndTorque.basicForce.force[3](quantity = "Force", unit = "N") "x-, y-, z-coordinates of force";
//   Real force[1].y "Connector of Real output signal";
//   parameter Real force[1].k(start = 1.0) = 0.0 "Constant output value";
//   Real force[2].y "Connector of Real output signal";
//   parameter Real force[2].k(start = 1.0) = 1000.0 "Constant output value";
//   Real force[3].y "Connector of Real output signal";
//   parameter Real force[3].k(start = 1.0) = 0.0 "Constant output value";
// equation
//   force[1].y = force[1].k;
//   force[2].y = force[2].k;
//   force[3].y = force[3].k;
//   forceAndTorque.basicForce.force[1] = forceAndTorque.force[1];
//   forceAndTorque.basicForce.force[2] = forceAndTorque.force[2];
//   forceAndTorque.basicForce.force[3] = forceAndTorque.force[3];
//   force[1].y = forceAndTorque.force[1];
//   force[2].y = forceAndTorque.force[2];
//   force[3].y = forceAndTorque.force[3];
// end ForceAndTorque;
// endResult
