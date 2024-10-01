// name: IfEquation9
// keywords:
// status: correct
//

model A
  Real x;
  parameter Boolean b;
equation
  if b then
    x = 2;
  else
    x = 3;
  end if;
end A;

model IfEquation9
  parameter Boolean barr[6] = {false, false, true, false, true, false};
  A a[4](b = barr[1:4]);
end IfEquation9;

// Result:
// class IfEquation9
//   parameter Boolean barr[1] = false;
//   parameter Boolean barr[2] = false;
//   parameter Boolean barr[3] = true;
//   parameter Boolean barr[4] = false;
//   parameter Boolean barr[5] = true;
//   parameter Boolean barr[6] = false;
//   Real a[1].x;
//   final parameter Boolean a[1].b = false;
//   Real a[2].x;
//   final parameter Boolean a[2].b = false;
//   Real a[3].x;
//   final parameter Boolean a[3].b = true;
//   Real a[4].x;
//   final parameter Boolean a[4].b = false;
// equation
//   a[1].x = 3.0;
//   a[2].x = 3.0;
//   a[3].x = 2.0;
//   a[4].x = 3.0;
// end IfEquation9;
// endResult
