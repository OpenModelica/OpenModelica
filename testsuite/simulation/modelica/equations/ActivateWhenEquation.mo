// name:     ActivateWhenEquation
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
// Drmodelica: 8.2 Conditional Equations with when-Equations (p. 246)


class Activate
  constant Real x = 4;
  Real y, z;
equation
  when initial() then y = x + 3; // Equations to be activated at the beginning
  end when;
  when terminal() then z = x - 2; // Equations to be activated at the end of the simulation
  end when;
end Activate;

//
// class Activate
// constant Real x = 4;
// Real y;
// Real z;
// equation
//  when initial() then
//  y = 7.0;
//  end when;
//  when terminal() then
//  z = 2.0;
//  end when;
// end Activate;
