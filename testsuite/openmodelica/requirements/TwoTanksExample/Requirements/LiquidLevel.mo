within TwoTanksExample.Requirements;

model LiquidLevel
 extends VVDRlib.Verification.Requirement;
 input Real waterLevel;
 equation
  status = if (waterLevel < 8) then
   VVDRlib.ReqStatus.NOT_VIOLATED else VVDRlib.ReqStatus.VIOLATED;
end LiquidLevel;