package Pck
  model TestRename
    flow Real x;
    Real y;

  equation
    x = 0.2;
  end TestRename;

  model TestRenameExt
    extends TestRename;
    Real z1;
    Real z2;

  end TestRenameExt;

  model TestRenameExt2
    extends TestRename;
    Real zx1;
    Real zx2;

  end TestRenameExt2;

end Pck;

model TestRenameExt3
  extends Pck.TestRenameExt2;
  Real az1;
  Real az2;

end TestRenameExt3;

package Pck2
  model TestRenameComp
    Pck.TestRenameExt testRenameExt;
    TestRenameExt3 testRenameExt3;

  end TestRenameComp;
end Pck2;

model TestRenameComp2
  import A=Pck.TestRenameExt;
  import Pck2.TestRenameComp;
  Pck2.TestRenameComp pck_testRenameComp;
  A a;
  TestRenameComp b;
equation
  a.x = 2.3;
  pck_testRenameComp.testRenameExt.x = 3.4;
  b.testRenameExt.x = 3.4;

  when a.x >= 3 or b.testRenameExt.x >= 3 then
    pck_testRenameComp.testRenameExt.x =4;

  end when;
  if a.x >= 5 then
    pck_testRenameComp.testRenameExt.x=3;

  else
    b.testRenameExt.x =4;

  end if;
  for i in 1:5 loop
    b.testRenameExt.x = 3;

  end for;

end TestRenameComp2;


model m1
 Modelica.Electrical.Analog.Basic.EMF emf1;
end m1;
