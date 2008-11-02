model BouncingBall3D
  import Modelica.SimpleVisual;
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g=9.81 "gravity acceleration";
  Real h(start=10) "height of ball";
  Real v "velocity of ball";
  Boolean flying(start=true) "true, if ball is flying";
  Boolean impact;
  Real v_new;
  SimpleVisual.PositionSize obj "color=blue;shape=sphere;";
equation
  impact= h < 0.0;
  der(v)=if flying then -g else 0;
  der(h)=v;

  obj.size[1]=5;
  obj.size[2]=5;
  obj.size[3]=5;
  obj.frame_a[1]=0;
  obj.frame_a[2]=h+obj.size[2]/2;
  obj.frame_a[3]=0;

  when {h <= 0.0 and v <= 0.0,impact} then
    v_new=if edge(impact) then -e*pre(v) else 0;
    flying=v_new > 0;
    reinit(v, v_new);
  end when;
end BouncingBall3D;
