// name:     ActivateWhenEquation
// keywords: <insert keywords here>
// status:   correct
//
// Drmodelica: 3.4 Access Control (p. 88)
//

class Activate
  constant Real x = 4;
  Real y, z;
equation
  when initial() then y = x + 3; // Equations to be activated at the beginning
  end when;
  when terminal() then z = x - 2; // Equations to be activated at the end of the simulation
  end when;
end Activate;

// Result:
// class Activate
//   constant Real x = 4.0;
//   Real y;
//   Real z;
// equation
//   when initial() then
//   y = 7.0;
//   end when;
//   when terminal() then
//   z = 2.0;
//   end when;
// end Activate;
// endResult
