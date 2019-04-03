// name: CevalNoEvent1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalNoEvent1
  constant Real r1 = noEvent(1.0 / 4.0);
end CevalNoEvent1;

// Result:
// class CevalNoEvent1
//   constant Real r1 = 0.25;
// end CevalNoEvent1;
// endResult
