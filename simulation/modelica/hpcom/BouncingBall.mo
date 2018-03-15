model BouncingBall
  parameter Real e = 0.7;
  parameter Real g = 9.81;
  Real h(start=1);
  Real v;
  Boolean flying(start=true);
  Boolean impact;
  Real v_new;
equation
  impact = h<=0.0;
  der(v)=if flying then -g else 0;
  der(h) = v;
    when {h<=0.0 and v <= 0.0, impact} then
      v_new=if edge(impact) then -e*pre(v) else 0;
      flying = v_new > 0;
      reinit(v,v_new);
    end when;
end BouncingBall;

