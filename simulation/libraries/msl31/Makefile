TEST = ../../../rtest -v

TESTFILES = \
Modelica.Blocks.CombiTables.mos \
Modelica.Blocks.Examples.BusUsage.mos \
Modelica.Blocks.Examples.InverseModel.mos \
Modelica.Blocks.Examples.LogicalNetwork1.mos \
Modelica.Blocks.Examples.ShowLogicalSources.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassAnalog.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassOPV.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos \
Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodes.mos \
Modelica.Electrical.Analog.Examples.CharacteristicThyristors.mos \
Modelica.Electrical.Analog.Examples.ChuaCircuit.mos \
Modelica.Electrical.Analog.Examples.CompareTransformers.mos \
Modelica.Electrical.Analog.Examples.HeatingMOSInverter.mos \
Modelica.Electrical.Analog.Examples.HeatingRectifier.mos \
Modelica.Electrical.Analog.Examples.HeatingResistor.mos \
Modelica.Electrical.Analog.Examples.ShowSaturatingInductor.mos \
Modelica.Electrical.Analog.Examples.ShowVariableResistor.mos \
Modelica.Electrical.Machines.Examples.DCSE_Start.mos \
Modelica.Electrical.Machines.Examples.TransformerTestbench.mos \
Modelica.Electrical.MultiPhase.Examples.TransformerYY.mos \
Modelica.Electrical.MultiPhase.Examples.TransformerYD.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.InitSpringConstant.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ForceAndTorque.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.FreeBody.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PendulumWithSpringDamper.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetDriving.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetPulling.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringDamperSystem.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringMassSystem.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringWithMass.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.LineForceWithTwoMasses.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravity.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheel.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar1.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar2.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.PlanarLoops_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.ActuatedDrive.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GearConstraint.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.MovingActuatedDrive.mos \
Modelica.Mechanics.MultiBody.Frames.mos \
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.oneAxis.mos \
Modelica.Mechanics.Rotational.Examples.Backlash.mos \
Modelica.Mechanics.Rotational.Examples.First.mos \
Modelica.Mechanics.Rotational.Examples.FirstGrounded.mos \
Modelica.Mechanics.Rotational.Examples.Friction.mos \
Modelica.Mechanics.Rotational.Examples.ElasticBearing.mos \
Modelica.Mechanics.Rotational.Examples.LossyGearDemo1.mos \
Modelica.Mechanics.Rotational.Examples.RollingWheel.mos \
Modelica.Mechanics.Translational.Examples.Accelerate.mos \
Modelica.Mechanics.Translational.Examples.Brake.mos \
Modelica.Mechanics.Translational.Examples.Damper.mos \
Modelica.Mechanics.Translational.Examples.ElastoGap.mos \
Modelica.Mechanics.Translational.Examples.Friction.mos \
Modelica.Mechanics.Translational.Examples.InitialConditions.mos \
Modelica.Mechanics.Translational.Examples.Oscillator.mos \
Modelica.Mechanics.Translational.Examples.PreLoad.mos \
Modelica.Mechanics.Translational.Examples.Sensors.mos \
Modelica.Mechanics.Translational.Examples.SignConvention.mos \
Modelica.Mechanics.Translational.Examples.WhyArrows.mos \
Modelica.Thermal.FluidHeatFlow.Examples.IndirectCooling.mos \
Modelica.Thermal.FluidHeatFlow.Examples.OneMass.mos \
Modelica.Thermal.FluidHeatFlow.Examples.ParallelCooling.mos \
Modelica.Thermal.FluidHeatFlow.Examples.PumpAndValve.mos \
Modelica.Thermal.FluidHeatFlow.Examples.PumpDropOut.mos \
Modelica.Thermal.FluidHeatFlow.Examples.SimpleCooling.mos \
Modelica.Thermal.FluidHeatFlow.Examples.TwoMass.mos \
Modelica.Thermal.HeatTransfer.Examples.Motor.mos \
Modelica.Thermal.HeatTransfer.Examples.ControlledTemperature.mos \
Modelica.Thermal.HeatTransfer.Examples.TwoMasses.mos \
Modelica.Math.Matrices.norm.mos \
Modelica.Math.Matrices.mos 

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \
$(WRONGRESULTTEST)  
#$(NOTCOMPILETEST) \
#$(NOTSIMULATETEST) \


NOTCOMPILETEST= \
Modelica.Electrical.Analog.Examples.AmplifierWithOpAmpDetailed.mos \
Modelica.Electrical.Digital.Examples.Counter.mos \
Modelica.Electrical.Digital.Examples.Counter3.mos \
Modelica.Electrical.Digital.Examples.FlipFlop.mos \
Modelica.Electrical.Digital.Examples.FullAdder.mos \
Modelica.Electrical.Digital.Examples.Multiplexer.mos


NOTSIMULATETEST= \
Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc.mos \
Modelica.Electrical.Analog.Examples.SwitchWithArc.mos \
Modelica.Electrical.Machines.Examples.Rectifier6pulse.mos \
Modelica.Electrical.Machines.Examples.Rectifier12pulse.mos \
Modelica.Electrical.Machines.Examples.SMEE_Generator.mos \
Modelica.Electrical.Machines.Examples.SMPM_Inverter.mos \
Modelica.Electrical.Machines.Examples.SMR_Inverter.mos \
Modelica.Electrical.MultiPhase.Examples.Rectifier.mos \
Modelica.Magnetic.FluxTubes.Examples.MovingCoilActuator.ForceCurrentBehaviour.mos \
Modelica.Magnetic.FluxTubes.Examples.MovingCoilActuator.ForceStrokeBehaviour.mos \
Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator.ComparisonPullInStroke.mos \
Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator.ComparisonQuasiStationary.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos \
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot.mos \
Modelica.Mechanics.Rotational.Examples.CoupledClutches.mos \
Modelica.StateGraph.Examples.ControlledTanks.mos \
Modelica.Thermal.FluidHeatFlow.Examples.ParallelPumpDropOut.mos \
Modelica.Electrical.Machines.Examples.AIMC_DOL.mos \
Modelica.Electrical.Machines.Examples.AIMS_Start.mos \
Modelica.Electrical.Machines.Examples.AIMC_YD.mos \
Modelica.Electrical.Machines.Examples.AIMC_Steinmetz.mos \
Modelica.Electrical.Machines.Examples.AIMC_Inverter.mos \
RectifierOM.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses2.mos \



WRONGRESULTTEST = \
Modelica.Blocks.Examples.PID_Controller.mos \
Modelica.Electrical.Analog.Examples.DifferenceAmplifier.mos \
Modelica.Electrical.Analog.Examples.HeatingNPN_OrGate.mos \
Modelica.Electrical.Analog.Examples.OvervoltageProtection.mos \
Modelica.Electrical.Analog.Examples.NandGate.mos \
Modelica.Electrical.Analog.Examples.ThyristorBehaviourTest.mos \
Modelica.Electrical.Analog.Examples.Rectifier.mos \
Modelica.Electrical.Digital.Examples.Adder4.mos \
Modelica.Electrical.Digital.Examples.HalfAdder.mos \
Modelica.Electrical.Machines.Examples.DCEE_Start.mos \
Modelica.Electrical.Machines.Examples.DCPM_Start.mos \
Modelica.Magnetic.FluxTubes.Examples.MovingCoilActuator.ArmatureStroke.mos \
Modelica.Magnetic.FluxTubes.Examples.SaturatedInductor.mos \
Modelica.Mechanics.Rotational.Examples.LossyGearDemo2.mos \
Modelica.StateGraph.Examples.ExecutionPaths.mos \
Modelica.StateGraph.Examples.FirstExample.mos \
Modelica.StateGraph.Examples.FirstExample_Variant2.mos \
Modelica.StateGraph.Examples.FirstExample_Variant3.mos \
Modelica.StateGraph.Examples.ShowCompositeStep.mos \
Modelica.StateGraph.Examples.ShowExceptions.mos \
Modelica.Utilities.Examples.readRealParameterModel.mos \
ThyrGTO.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GyroscopicEffects.mos \



# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 



CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest


test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES) 
	
# Cleans all files that are not listed as dependencies 
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)

# Run this if you want to list out the files (dependencies).
# do it after cleaning and updating the folder
# then you can get a list of file names (which must be dependencies
# since you got them from repository + your own new files)
# then add them to the DEPENDENCIES. You can find the 
# list in deps.txt
getdeps: 
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt	
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES
	
failingtest :
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES) \
	
