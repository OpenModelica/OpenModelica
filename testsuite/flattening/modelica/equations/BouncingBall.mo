// name:     BouncingBall
// keywords: when semantics, equation
// status:   correct
//
// Drmodelica: 9.1 reinit (p. 296)
//

model BouncingBall     "The bouncing ball model"
  constant Real g = 9.81;  // Gravitational acceleration
  parameter Real c = 0.9;  // Elasticity constant of ball
  parameter Real radius = 0.1;  // Radius of the ball
  Real height(start = 1);  // height above ground of the ball center
  Real velocity(start = 0);  // Velocity of the ball
equation
  der(height) = velocity;
  der(velocity) = -g;
  when height <= radius then
    reinit(velocity, -c*pre(velocity));
  end when;
end BouncingBall;


// Result:
// class BouncingBall "The bouncing ball model"
//   constant Real g = 9.81;
//   parameter Real c = 0.9;
//   parameter Real radius = 0.1;
//   Real height(start = 1.0);
//   Real velocity(start = 0.0);
// equation
//   der(height) = velocity;
//   der(velocity) = -9.81;
//   when height <= radius then
//     reinit(velocity, (-c) * pre(velocity));
//   end when;
// end BouncingBall;
// endResult
