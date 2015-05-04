#!/bin/sh

OMC='/c/bin/cygwin/home/adrpo/dev/OpenModelica/build/bin/omc.exe +locale=C +d=showStatement '

cd ./electrical

time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos
time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos
time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodes.mos
time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodes.mos
time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CharacteristicThyristors.mos
time ${OMC} omc_simulate_Modelica.Electrical.Analog.Examples.CharacteristicThyristors.mos
rm -f *.exe *.c *.h *.libs *.makefile *.mat *.o *.log *.xml

cd ../fluid

time ${OMC} omc_check_Modelica.Fluid.Examples.ControlledTankSystem.ControlledTanks.mos
time ${OMC} omc_check_Modelica.Fluid.Examples.ControlledTankSystem.ControlledTanks.mos
time ${OMC} omc_check_Modelica.Fluid.Examples.DrumBoiler.DrumBoiler.mos
time ${OMC} omc_check_Modelica.Fluid.Examples.DrumBoiler.DrumBoiler.mos
time ${OMC} omc_check_Modelica.Fluid.Examples.Explanatory.MeasuringTemperature.mos
time ${OMC} omc_check_Modelica.Fluid.Examples.Explanatory.MeasuringTemperature.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.ControlledTankSystem.ControlledTanks.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.ControlledTankSystem.ControlledTanks.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.DrumBoiler.DrumBoiler.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.DrumBoiler.DrumBoiler.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.Explanatory.MeasuringTemperature.mos
time ${OMC} omc_simulate_Modelica.Fluid.Examples.Explanatory.MeasuringTemperature.mos
rm -f *.exe *.c *.h *.libs *.makefile *.mat *.o *.log *.xml

cd ../multibody

time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b_analytic.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b_analytic.mos
#time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos
#time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot.mos
time ${OMC} omc_simulate_Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot.mos
rm -f *.exe *.c *.h *.libs *.makefile *.mat *.o *.log *.xml

