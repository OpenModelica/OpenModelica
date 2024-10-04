// name: FuncBuiltinReduction
// keywords: reduction
// status: correct
//
// Tests the builtin reduction operators.
//

model FuncBuiltinReduction
  type E = enumeration(one, two, three);

  Real r1 = min(r*2 for r in {1.0, 2, 3, 4});
  Real r2 = max(r*r for r in {-4.0, -2.0, 3.0, 5.0});
  Real r3 = sum(r*2.0 for r in 1:10);
  Real r4 = product(r^2 for r in 1:5);
  Real r5 = sum(x*y*1.0 for x in 1:4, y in 3:9);
  Real r6 = min(r*2.0 for r in 1:0);
  Real r7 = max(r*2.0 for r in 1:0);
  Real r8 = sum(r*2.0 for r in 1:0);
  Real r9 = product(r*2.0 for r in 1:0);
  Real r10 = sum(r1*r2 for r1 in 1:integer(time), r2 in 1:4);

  Integer i1 = min(i-1 for i in {2, 4, 1});
  Integer i2 = max(i for i in {4, 2, 9});
  Integer i3 = sum(i*i for i in {1, 2, 3});
  Integer i4 = product(i for i in 4:9);
  Integer i5 = min(i for i in 1:0);
  Integer i6 = max(i for i in 1:0);
  Integer i7 = sum(i for i in 1:0);
  Integer i8 = product(i for i in 1:0);

  Boolean b1 = min(not b for b in {false, true});
  Boolean b2 = max(i == 2 for i in 1:4);
  Boolean b3 = min(b for b in true:false);
  Boolean b4 = max(b for b in true:false);
  
  E e1 = min(e for e in E.one:E.three);
  E e2 = max(e for e in E);
  E e3 = min(e for e in E.three:E.one);
  E e4 = max(e for e in E.three:E.one);
end FuncBuiltinReduction;

// Result:
// class FuncBuiltinReduction
//   Real r1 = 2.0;
//   Real r2 = 25.0;
//   Real r3 = 110.0;
//   Real r4 = 14400.0;
//   Real r5 = 420.0;
//   Real r6 = 8.777798510069901e304;
//   Real r7 = -8.777798510069901e304;
//   Real r8 = 0.0;
//   Real r9 = 1.0;
//   Real r10 = /*Real*/(sum(sum(r1 * r2 for r1 in 1:integer(time)) for r2 in 1:4));
//   Integer i1 = 0;
//   Integer i2 = 9;
//   Integer i3 = 14;
//   Integer i4 = 60480;
//   Integer i5 = 4611686018427387903;
//   Integer i6 = -4611686018427387903;
//   Integer i7 = 0;
//   Integer i8 = 1;
//   Boolean b1 = false;
//   Boolean b2 = true;
//   Boolean b3 = true;
//   Boolean b4 = false;
//   enumeration(one, two, three) e1 = E.one;
//   enumeration(one, two, three) e2 = E.three;
//   enumeration(one, two, three) e3 = E.three;
//   enumeration(one, two, three) e4 = E.one;
// end FuncBuiltinReduction;
// endResult
