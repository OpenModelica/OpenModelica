// name: CevalMatrixPow1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalRelation1
  constant Boolean br1 = 0.1 < 0.0;
  constant Boolean br2 = 0.1 <= 0.0;
  constant Boolean br3 = 0.1 > 0.0;
  constant Boolean br4 = 0.1 >= 0.0;

  constant Boolean bi1 = 1 < 0;
  constant Boolean bi2 = 1 <= 0;
  constant Boolean bi3 = 1 > 0;
  constant Boolean bi4 = 1 >= 0;
  constant Boolean bi5 = 1 == 0;
  constant Boolean bi6 = 1 <> 0;

  type E = enumeration(one, two, three);
  constant Boolean be1 = E.one < E.two;
  constant Boolean be2 = E.one <= E.two;
  constant Boolean be3 = E.one > E.two;
  constant Boolean be4 = E.one >= E.two;
  constant Boolean be5 = E.one == E.two;
  constant Boolean be6 = E.one <> E.two;

  constant Boolean bb1 = true < false;
  constant Boolean bb2 = true <= false;
  constant Boolean bb3 = true > false;
  constant Boolean bb4 = true >= false;
  constant Boolean bb5 = true == false;
  constant Boolean bb6 = true <> false;

  constant Boolean bs1 = "1" < "2";
  constant Boolean bs2 = "1" <= "2";
  constant Boolean bs3 = "1" > "2";
  constant Boolean bs4 = "1" >= "2";
  constant Boolean bs5 = "1" == "2";
  constant Boolean bs6 = "1" <> "2";
end CevalRelation1;

// Result:
// class CevalRelation1
//   constant Boolean br1 = false;
//   constant Boolean br2 = false;
//   constant Boolean br3 = true;
//   constant Boolean br4 = true;
//   constant Boolean bi1 = false;
//   constant Boolean bi2 = false;
//   constant Boolean bi3 = true;
//   constant Boolean bi4 = true;
//   constant Boolean bi5 = false;
//   constant Boolean bi6 = true;
//   constant Boolean be1 = true;
//   constant Boolean be2 = true;
//   constant Boolean be3 = false;
//   constant Boolean be4 = false;
//   constant Boolean be5 = false;
//   constant Boolean be6 = true;
//   constant Boolean bb1 = false;
//   constant Boolean bb2 = false;
//   constant Boolean bb3 = true;
//   constant Boolean bb4 = true;
//   constant Boolean bb5 = false;
//   constant Boolean bb6 = true;
//   constant Boolean bs1 = true;
//   constant Boolean bs2 = true;
//   constant Boolean bs3 = false;
//   constant Boolean bs4 = false;
//   constant Boolean bs5 = false;
//   constant Boolean bs6 = true;
// end CevalRelation1;
// endResult
