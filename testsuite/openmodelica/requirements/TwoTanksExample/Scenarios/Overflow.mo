within TwoTanksExample.Scenarios;
model Overflow
extends VVDRlib.Verification.Scenario;
output Real flowLevel(start = 0.5);

equation
  when time > 5 then
    flowLevel = 1.5;
  end when;

end Overflow ;