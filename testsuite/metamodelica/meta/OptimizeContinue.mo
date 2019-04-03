// name: OptimizeContinue
// cflags: -g=MetaModelica -d=patternmAllInfo,gen
// status: correct
// teardown_command: rm -f OptimizeContinue_*

model OptimizeContinue
  uniontype Ut
    record UT1 end UT1;
    record UT2 end UT2;
    record UT3 end UT3;
  end Ut;
  uniontype Ut2
    record UT4 Integer i; end UT4;
    record UT5 Integer i; end UT5;
    record UT6 Integer i; end UT6;
  end Ut2;

  function f
    output Real r;
  algorithm
    r := matchcontinue UT1()
      case UT1() then 1.0;
      case UT2() then 2.0;
      case UT3() then 3.0;
    end matchcontinue;
    r := matchcontinue UT4(1)
      case UT4(1) then 1.0;
      case UT4(2) then 2.0;
    end matchcontinue;
    r := matchcontinue UT1()
      case UT1() then 1.0;
      case UT1() then 2.0;
    end matchcontinue;
    r := matchcontinue UT4(1)
      case UT4(1) then 1.0;
      case UT4() then 2.0;
    end matchcontinue;
  end f;
  constant Real r = f();
end OptimizeContinue;
// Result:
// function OptimizeContinue.f
//   output Real r;
// algorithm
//   r := match /* switch */ (OptimizeContinue.Ut.UT1())
//       case (OptimizeContinue.Ut.UT1()) then 1.0;
//       case (OptimizeContinue.Ut.UT2()) then 2.0;
//       case (OptimizeContinue.Ut.UT3()) then 3.0;
//     end match /* switch */;
//   r := match (OptimizeContinue.Ut2.UT4(#(1)))
//       case (OptimizeContinue.Ut2.UT4(1)) then 1.0;
//       case (OptimizeContinue.Ut2.UT4(2)) then 2.0;
//     end match;
//   r := matchcontinue (OptimizeContinue.Ut.UT1())
//       case (OptimizeContinue.Ut.UT1()) then 1.0;
//       case (OptimizeContinue.Ut.UT1()) then 2.0;
//     end matchcontinue;
//   r := matchcontinue (OptimizeContinue.Ut2.UT4(#(1)))
//       case (OptimizeContinue.Ut2.UT4(1)) then 1.0;
//       case (OptimizeContinue.Ut2.UT4(_)) then 2.0;
//     end matchcontinue;
// end OptimizeContinue.f;
//
// class OptimizeContinue
//   constant Real r = 1.0;
// end OptimizeContinue;
// [metamodelica/meta/OptimizeContinue.mo:21:5-25:22:writable] Notification: This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.
// [metamodelica/meta/OptimizeContinue.mo:21:5-25:22:writable] Notification: Converted match expression to switch of type #T_UNKNOWN#.
// [metamodelica/meta/OptimizeContinue.mo:21:5-25:22:writable] Notification: Match input OptimizeContinue.Ut.UT1() is a constant value.
// [metamodelica/meta/OptimizeContinue.mo:26:5-29:22:writable] Notification: This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.
// [metamodelica/meta/OptimizeContinue.mo:26:5-29:22:writable] Notification: Match input OptimizeContinue.Ut2.UT4(#(1)) is a constant value.
// [metamodelica/meta/OptimizeContinue.mo:30:5-33:22:writable] Notification: Match input OptimizeContinue.Ut.UT1() is a constant value.
// [metamodelica/meta/OptimizeContinue.mo:34:5-37:22:writable] Notification: Match input OptimizeContinue.Ut2.UT4(#(1)) is a constant value.
//
// endResult
