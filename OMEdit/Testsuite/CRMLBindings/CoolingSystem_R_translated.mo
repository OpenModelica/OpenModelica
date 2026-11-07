within ;
model CoolingSystem_R
model Pump_R
CRMLtoModelica.Types.Boolean4 inOperation;
CRMLtoModelica.Types.Boolean4 cavitate;
CRMLtoModelica.Types.Boolean4 R2 =  if (inOperation== CRMLtoModelica.Types.Boolean4.true4) then CRMLtoModelica.Functions.not4( cavitate) else CRMLtoModelica.Types.Boolean4.undefined;
end Pump_R;
parameter Integer pumps_n(min = 0) = 0 "Number of elements of external set pumps";
Pump_R pumps[pumps_n];
CRMLtoModelica.Types.Boolean4 R2 = CRMLtoModelica_Blocks_setAnd0.out;
CRMLtoModelica.Blocks.setAnd CRMLtoModelica_Blocks_setAnd0(r1 = pumps.R2);
end CoolingSystem_R;
