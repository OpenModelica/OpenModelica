partial package PartialMedium

  constant Integer nX = size(reference_X,1);
  constant Real reference_X[:] = {1,2};

  model BaseProperties
    Real[nXi] Xi = reference_X;
    parameter Integer nXi;
    parameter Boolean b = nX == 4;
  end BaseProperties;

end PartialMedium;

package TableBased
  extends PartialMedium(reference_X = {1,2,3,4});
  model BP
    extends BaseProperties(nXi = if b then 4 else 2);
  end BP;
end TableBased;

model BaseClass1
  TableBased.BP medium;
end BaseClass1;
