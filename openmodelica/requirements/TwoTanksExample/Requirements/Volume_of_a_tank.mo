within TwoTanksExample.Requirements;

model Volume_of_a_tank "The volume of each tank shall be at least 2 m3. "
extends VVDRlib.Verification.Requirement;
input Real tankVolume;
parameter Modelica.SIunits.Volume requiredVolume = 2;
equation
 status = if tankVolume < requiredVolume
  then VVDRlib.ReqStatus.VIOLATED else   VVDRlib.ReqStatus.NOT_VIOLATED;
end Volume_of_a_tank;