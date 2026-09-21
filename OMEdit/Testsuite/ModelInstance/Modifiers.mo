package Modifiers
  model A
    Real x;
  end A;

  model M
    A a(R = 1, V(start = 2), X = sin(time), Y(min = 2) = if time < 1 then 0 else 1);
  end M;
end Modifiers;
