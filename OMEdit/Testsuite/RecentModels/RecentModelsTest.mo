package RecentModelsTest
  model M
    Real x(start = 1, fixed = true);
  equation
    der(x) = -x;
  end M;
end RecentModelsTest;
