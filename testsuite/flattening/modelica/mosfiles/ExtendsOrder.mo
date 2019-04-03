partial package PM1
  partial model BP1
    parameter Integer nXi;
    Real[nXi] Xi(start = {1.0,2.0});
  end BP1;
end PM1;

package TB1
  extends PM1;
  model BP1_1
    extends BP1(nXi = 2);
  end BP1_1;
end TB1;

model Order1
  TB1.BP1_1 m;
end Order1;

partial package PM2
  partial model BP2
    parameter Integer nXi;
    Real[nXi] Xi(start = {1.0,2.0});
  end BP2;
end PM2;

package TB2
  extends PM2;
  model BP2_1
    extends BP2(nXi = 2);
  end BP2_1;
end TB2;

model Order2
  TB2.BP2_1 m;
end Order2;
