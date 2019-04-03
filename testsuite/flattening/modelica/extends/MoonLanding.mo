// name:     MoonLanding
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK ON THIS FILE HAS TO BE DONE!
// Drmodelica: 4.1  Moon Landing (p. 115)
//

model Body "Generic body"
  Real mass;
  String name;
end Body;

model CelestialBody "Celestial body"
  extends Body;
  constant Real g = 6.672e-11;
  parameter Real radius;
end CelestialBody;

class Rocket
  extends Body;
  Real altitude(start = 59404);
  Real velocity(start = -2003);
  Real acceleration;
  Real thrust; // Thrust force on the rocket
  Real gravity; // Gravity forcefield
  parameter Real massLossRate = 0.000277;
equation
  (thrust - mass*gravity) / mass = acceleration;
  der(mass) = -massLossRate * abs(thrust);
  der(altitude) = velocity;
  der(velocity) = acceleration;
end Rocket;

model MoonLanding
  parameter Real force1 = 36350;
  parameter Real force2 = 1308;
  parameter Real thrustEndTime = 210;
  parameter Real thrustDecreaseTime = 43.2;
  Rocket apollo(name = "Apollo13", mass(start=1038.358));
  CelestialBody moon(name = "moon", mass = 7.382e22,radius = 1.738e6);
equation
  apollo.thrust = if (time < thrustDecreaseTime) then force1
  else if (time < thrustEndTime) then force2
  else 0;
  apollo.gravity = moon.g*moon.mass/(apollo.altitude + moon.radius)^2;
end MoonLanding;

// Result:
// class MoonLanding
//   parameter Real force1 = 36350.0;
//   parameter Real force2 = 1308.0;
//   parameter Real thrustEndTime = 210.0;
//   parameter Real thrustDecreaseTime = 43.2;
//   Real apollo.mass(start = 1038.358);
//   String apollo.name = "Apollo13";
//   Real apollo.altitude(start = 59404.0);
//   Real apollo.velocity(start = -2003.0);
//   Real apollo.acceleration;
//   Real apollo.thrust;
//   Real apollo.gravity;
//   parameter Real apollo.massLossRate = 0.000277;
//   Real moon.mass = 7.382e+22;
//   String moon.name = "moon";
//   constant Real moon.g = 0.00000000006672;
//   parameter Real moon.radius = 1738000.0;
// equation
//   (apollo.thrust - apollo.mass * apollo.gravity) / apollo.mass = apollo.acceleration;
//   der(apollo.mass) = (-apollo.massLossRate) * abs(apollo.thrust);
//   der(apollo.altitude) = apollo.velocity;
//   der(apollo.velocity) = apollo.acceleration;
//   apollo.thrust = if time < thrustDecreaseTime then force1 else if time < thrustEndTime then force2 else 0.0;
//   apollo.gravity = 0.00000000006672 * moon.mass / (apollo.altitude + moon.radius) ^ 2.0;
// end MoonLanding;
// endResult
