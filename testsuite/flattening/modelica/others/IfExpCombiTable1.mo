// name: IfExpCombiTable1
// status: correct
// This should succeed without error messages

model IfExpCombiTable1
  function q
    output Real y;
    external "C" y = q_not_linked();
  end q;
  parameter Boolean b = false;
  Real r = if not b then 1.5 else q();
end IfExpCombiTable1;

// Result:
// impure function IfExpCombiTable1.q
//   output Real y;
//
//   external "C" y = q_not_linked();
// end IfExpCombiTable1.q;
//
// class IfExpCombiTable1
//   parameter Boolean b = false;
//   Real r = if not b then 1.5 else IfExpCombiTable1.q();
// end IfExpCombiTable1;
// endResult
