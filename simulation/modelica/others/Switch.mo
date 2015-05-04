// name:     Switch
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//
// Drmodelica:
//
model Switch
  Real v;
  Real i;
  Real i1;
  Real itot;
  Boolean open;
equation
  itot = i + i1;
  if open then
    v = 0;
    else
      i = 0;
  end if;
    1 - i1 = 0;
    1 - v - i = 0;
    open = time >= 0.5;
end Switch;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class Switch
// Real v;
// Real i;
// Real i1;
// Real itot;
// Boolean open;
// equation
//   itot = i + i1;
//   0.0 = if open then v - 0.0 else i - 0.0;
//   1.0 - i1 = 0.0;
//   1.0 - v - i = 0.0;
//   open = time >= 0.5;
// end Switch;
