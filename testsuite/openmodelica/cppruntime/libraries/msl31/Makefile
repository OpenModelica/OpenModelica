TEST = ../../../../rtest -v

TESTFILES = \
Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ForceAndTorque.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.FreeBody.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.InitSpringConstant.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.LineForceWithTwoMasses.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PendulumWithSpringDamper.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravity.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses2.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheel.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetDriving.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetPulling.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringDamperSystem.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringMassSystem.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringWithMass.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar1.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar2.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.PlanarLoops_analytic.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.ActuatedDrive.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GearConstraint.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GyroscopicEffects.mos \
Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.MovingActuatedDrive.mos \
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot.mos \
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.oneAxis.mos \
Modelica.Mechanics.MultiBody.Frames.mos \
Modelica.Mechanics.Rotational.Examples.Backlash.mos \
Modelica.Mechanics.Rotational.Examples.CoupledClutches.mos \
Modelica.Mechanics.Rotational.Examples.ElasticBearing.mos \
Modelica.Mechanics.Rotational.Examples.First.mos \
Modelica.Mechanics.Rotational.Examples.FirstGrounded.mos \
Modelica.Mechanics.Rotational.Examples.Friction.mos \
Modelica.Mechanics.Rotational.Examples.LossyGearDemo1.mos \
Modelica.Mechanics.Rotational.Examples.LossyGearDemo2.mos \
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
Modelica.Mechanics.Translational.Examples.WhyArrows.mos


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES =  


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
*.mat


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
	
