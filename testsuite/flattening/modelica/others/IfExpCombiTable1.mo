// name: IfExpCombiTable1
// status: correct
// This should succeed without error messages

class IfExpCombiTable1
  parameter Boolean b = false;
  Real r = if not b then 1.5 else q();
end IfExpCombiTable1;

// Result:
// class IfExpCombiTable1
//   parameter Boolean b = false;
//   Real r = 1.5;
// end IfExpCombiTable1;
// endResult
