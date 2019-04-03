model Ticket4618
  firstState s1;
  secondState s2;
  Real t;
  inner Clock c = Clock(0.1);
  block firstState
    Real x1;
    outer Clock c;
  equation
    when c then
      x1 = previous(x1)+interval();
    end when;
  end firstState;

  block secondState
    Real x2;
    outer Clock c;
  equation
    when c then
      x2 = previous(x2)+interval();
    end when;
  end secondState;
equation
  t = sample(time,c);
  initialState(s1);
  transition(s1, s2, t > 0.5, immediate = false, reset = true, synchronize = false, priority = 1);
end Ticket4618;
