// name: TailRecursion
// cflags: -d=noevalfunc,tail,gen -g=MetaModelica
// status: correct

model TailRecursion
function last
  input Real x;
  output Real y = x;
algorithm
  if x > 200000.0 then return; end if;
  y := last(x+1.0);
end last;

function if_
  input Real x;
  output Real y;
algorithm
  y := if x > 200000.0 then x else if_(x+1.0);
end if_;

function match_
  input Real x;
  output Real y;
algorithm
  y := match realString(x)
    case "200000.5" then 200000.5;
    case "200000.0" then 200000.0;
    else match_(x+1.0);
  end match;
end match_;

  Real r1 = last(0.5);
  Real r2 = if_(0.5);
  Real r3 = match_(0.5);
end TailRecursion;

// Result:
// function TailRecursion.if_
//   input Real x;
//   output Real y;
// algorithm
//   y := if x > 200000.0 then x else TailRecursion.if_(1.0 + x);
// end TailRecursion.if_;
//
// function TailRecursion.last
//   input Real x;
//   output Real y = x;
// algorithm
//   if x > 200000.0 then
//     return;
//   end if;
//   return TailRecursion.last(1.0 + x);
// end TailRecursion.last;
//
// function TailRecursion.match_
//   input Real x;
//   output Real y;
// algorithm
//   y := match (realString(x))
//       case ("200000.5") then 200000.5;
//       case ("200000.0") then 200000.0;
//       case (_) then TailRecursion.match_(1.0 + x);
//     end match;
// end TailRecursion.match_;
//
// class TailRecursion
//   Real r1 = 200000.5;
//   Real r2 = 200000.5;
//   Real r3 = 200000.5;
// end TailRecursion;
// [metamodelica/meta/TailRecursion.mo:11:3-11:19:writable] Notification: Tail recursion of: TailRecursion.last(1.0 + x) with input vars: x
// [metamodelica/meta/TailRecursion.mo:18:3-18:46:writable] Notification: Tail recursion of: TailRecursion.if_(1.0 + x) with input vars: x
// [metamodelica/meta/TailRecursion.mo:25:3-29:12:writable] Notification: Tail recursion of: TailRecursion.match_(1.0 + x) with input vars: x
//
// endResult
