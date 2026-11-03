// name: ExtendsShort4
// keywords:
// status: correct
//
//

package P
  constant Real k = 2;
  model M
    Real x;
    Real y;
    Real z;
  end M;
  model M2 = M(x = k, y = 3);
  model M3 = M2(z = k + 1);
end P;

model ExtendsShort4
  constant Real k = 10;
  extends P.M3(y = 4);
end ExtendsShort4;

// Result:
// class ExtendsShort4
//   constant Real k = 10.0;
//   Real x = 2.0;
//   Real y = 4.0;
//   Real z = 3.0;
// end ExtendsShort4;
// endResult
