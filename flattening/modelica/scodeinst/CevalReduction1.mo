// name: CevalReduction1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalReduction1
  type E = enumeration(one, two, three);

  constant Real r1 = min(r*2 for r in {1.0, 2, 3, 4});
  constant Real r2 = max(r*r for r in {-4.0, -2.0, 3.0, 5.0});
  constant Real r3 = sum(r*2.0 for r in 1:10);
  constant Real r4 = product(r^2 for r in 1:5);
  constant Real r5 = sum(x*y*1.0 for x in 1:4, y in 3:9);
  constant Real r6 = min(r*2.0 for r in 1:0);
  constant Real r7 = max(r*2.0 for r in 1:0);
  constant Real r8 = sum(r*2.0 for r in 1:0);
  constant Real r9 = product(r*2.0 for r in 1:0);

  constant Integer i1 = min(i-1 for i in {2, 4, 1});
  constant Integer i2 = max(i for i in {4, 2, 9});
  constant Integer i3 = sum(i*i for i in {1, 2, 3});
  constant Integer i4 = product(i for i in 4:9);
  constant Integer i5 = min(i for i in 1:0);
  constant Integer i6 = max(i for i in 1:0);
  constant Integer i7 = sum(i for i in 1:0);
  constant Integer i8 = product(i for i in 1:0);

  constant Boolean b1 = min(not b for b in {false, true});
  constant Boolean b2 = max(i == 2 for i in 1:4);
  constant Boolean b3 = min(b for b in true:false);
  constant Boolean b4 = max(b for b in true:false);
  
  constant E e1 = min(e for e in E.one:E.three);
  constant E e2 = max(e for e in E);
  constant E e3 = min(e for e in E.three:E.one);
  constant E e4 = max(e for e in E.three:E.one);
end CevalReduction1;

// Result:
// class CevalReduction1
//   constant Real r1 = 2.0;
//   constant Real r2 = 25.0;
//   constant Real r3 = 110.0;
//   constant Real r4 = 14400.0;
//   constant Real r5 = 420.0;
//   constant Real r6 = 8.777798510069901e+304;
//   constant Real r7 = -8.777798510069901e+304;
//   constant Real r8 = 0.0;
//   constant Real r9 = 1.0;
//   constant Integer i1 = 0;
//   constant Integer i2 = 9;
//   constant Integer i3 = 14;
//   constant Integer i4 = 60480;
//   constant Integer i5 = 4611686018427387903;
//   constant Integer i6 = -4611686018427387903;
//   constant Integer i7 = 0;
//   constant Integer i8 = 1;
//   constant Boolean b1 = false;
//   constant Boolean b2 = true;
//   constant Boolean b3 = true;
//   constant Boolean b4 = false;
//   constant enumeration(one, two, three) e1 = E.one;
//   constant enumeration(one, two, three) e2 = E.three;
//   constant enumeration(one, two, three) e3 = E.three;
//   constant enumeration(one, two, three) e4 = E.one;
// end CevalReduction1;
// endResult
