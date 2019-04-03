package BB

  model Ball
    Real y;
    Real vy;
    Real ay;
  equation
    der(y) = vy;
    der(vy) = ay;
  end Ball;

  model BouncingBall
    parameter Real e(start = 0.9);
    Ball b1(y.start = 5, vy.start = 0);
    Real bounce_time(start=0);
  equation
    b1.ay = -9.8;
   when b1.y <= 0 and b1.vy <= 0 then
     bounce_time = time;
     reinit(b1.vy, -e * pre(b1.vy));
    end when;
  end BouncingBall;

end BB;
