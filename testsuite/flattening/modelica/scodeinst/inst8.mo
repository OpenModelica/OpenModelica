// name: inst8.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

package DummyPackage
  constant Integer nXi = 2;

  package PartialMedium
    model BaseProperties
      Real[nXi] Xi;
    end BaseProperties;
  end PartialMedium;
end DummyPackage;

model PartialSource
  package Medium = DummyPackage.PartialMedium;
  Medium.BaseProperties medium;
end PartialSource;

model M
  PartialSource ps;
end M;

// Result:
// class M
//   Real ps.medium.Xi[1];
//   Real ps.medium.Xi[2];
// end M;
// endResult
