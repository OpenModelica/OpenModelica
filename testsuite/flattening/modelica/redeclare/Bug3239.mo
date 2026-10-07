// name:     Bug3239.mo [BUG: #3239]
// keywords: redeclare modifier handling
// status:   correct
//
// check that modifiers on redeclare are not lost
//

block PI
 extends Der;
 parameter Real T(start = 1, min = -10000);
end PI;

block Der
end Der;

model m1
 replaceable Der outBlock;
end m1;

model m2
 extends m1(redeclare replaceable PI outBlock(T = 2.2));
end m2;

model m3
 extends m2(outBlock(T = 5.0));
end m3;

// Result:
// class m3
//   parameter Real outBlock.T(min = -10000.0, start = 1.0) = 5.0;
// end m3;
// endResult
