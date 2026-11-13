within;
block LimPID
  Modelica.Blocks.Continuous.Derivative D(
    final k=Td/unitTime,
    final T=max([Td/Nd,1.e-14]),
    final x_start=xd_start,
    final initType=if initType == Modelica.Blocks.Types.InitPID.SteadyState or
                initType == Modelica.Blocks.Types.InitPID.InitialOutput
             then
               Modelica.Blocks.Types.Init.SteadyState
             else
               if initType == Modelica.Blocks.Types.InitPID.InitialState then
                 Modelica.Blocks.Types.Init.InitialState
               else
                 Modelica.Blocks.Types.Init.NoInit) if with_D;
end LimPID;
