TEST = ../../../rtest -v

TESTFILES = \
ModelicaTest.Fluid.TestComponents.Machines.TestWaterPumpDCMotorHeatTransfer.mos \
ModelicaTest.Fluid.TestExamplesVariants.HeatingSystem_SteadyState.mos \
ModelicaTest.MultiBody.FourbarVariants.JointUSP.mos\
ModelicaTest.MultiBody.FourbarVariants.SphericalAndUniversal.mos\
ModelicaTest.MultiBody.FourbarVariants.SphericalSpherical.mos \
ModelicaTest.MultiBody.FourbarVariants.UniversalSpherical.mos \
ModelicaTest.MultiBody.Frames.AngularVelocity.mos \
ModelicaTest.MultiBody.Forces.DifferentiationOfForces.mos \
ModelicaTest.MultiBody.Forces.Force.mos \
ModelicaTest.MultiBody.Forces.Force2.mos \
ModelicaTest.MultiBody.Forces.ForcesAndTorques.mos \
ModelicaTest.MultiBody.Forces.ForceWithTwoMasses.mos \
ModelicaTest.MultiBody.Forces.FrameForces.mos \
ModelicaTest.MultiBody.Forces.FrameForcesAndTorques.mos \
ModelicaTest.MultiBody.Forces.FrameForcesAndTorques2.mos \
ModelicaTest.MultiBody.Forces.FrameTorques.mos \
ModelicaTest.MultiBody.Forces.LineForceWithMass.mos \
ModelicaTest.MultiBody.Forces.LineForceWithTwoMasses.mos \
ModelicaTest.MultiBody.Forces.Torque2.mos \
ModelicaTest.MultiBody.Forces.Spring.mos\
ModelicaTest.MultiBody.Forces.Damper.mos\
ModelicaTest.MultiBody.Forces.Spring2.mos\
ModelicaTest.MultiBody.Forces.WorldForces.mos\
ModelicaTest.MultiBody.Forces.WorldForces2.mos \
ModelicaTest.MultiBody.Forces.Worldtorque.mos \
ModelicaTest.MultiBody.Forces.WorldForceAndTorque.mos\
ModelicaTest.MultiBody.InitializationConversion.Bodies.mos\
ModelicaTest.MultiBody.InitializationConversion.Rotor1D.mos\
ModelicaTest.MultiBody.Parts.BodyShape.mos\
ModelicaTest.MultiBody.Parts.FreeBodies.mos\
ModelicaTest.MultiBody.Parts.PointMass.mos\
ModelicaTest.MultiBody.Parts.FixedRotation.mos\
ModelicaTest.MultiBody.Parts.FlyingBodies.mos\
ModelicaTest.MultiBody.Parts.FreeBodiesEnforceStatesFalse.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.Rotor1D_1.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.Rotor1D_2.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.Rotor1D_3.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.GearConstraint.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.GearConstraint2.mos\
ModelicaTest.MultiBody.Parts.Rotor1D.Beveal1d.mos\
ModelicaTest.MultiBody.Sensors.AbsoluteSensor.mos\
ModelicaTest.MultiBody.Sensors.AbsoluteSensor2.mos\
ModelicaTest.MultiBody.Sensors.CutForce.mos\
ModelicaTest.MultiBody.Sensors.CutForceAndTorque1.mos\
ModelicaTest.MultiBody.Sensors.CutTorque.mos\
ModelicaTest.MultiBody.Sensors.Distance.mos\
ModelicaTest.MultiBody.Sensors.Distance2.mos\
ModelicaTest.MultiBody.Sensors.RelativeSensor.mos\
ModelicaTest.MultiBody.Sensors.CutForceAndTorque2.mos\
ModelicaTest.MultiBody.Sensors.CutForceAndTorque3.mos\
ModelicaTest.MultiBody.Sensors.CutTorque2.mos\
ModelicaTest.MultiBody.Joints.FreeMotionScalarInit2.mos\
ModelicaTest.MultiBody.Joints.Revolute.mos\
ModelicaTest.MultiBody.Joints.Revolute2.mos\
ModelicaTest.MultiBody.Joints.RevoluteInitialization.mos\
ModelicaTest.MultiBody.Joints.CheckConstaintTorqueUniversalJoint.mos \
ModelicaTest.MultiBody.Joints.Cylindrical.mos \
ModelicaTest.MultiBody.Joints.FreeMotion.mos \
ModelicaTest.MultiBody.Joints.FreeMotionScalarInit2.mos \
ModelicaTest.MultiBody.Joints.JointUSP.mos\
ModelicaTest.MultiBody.Joints.JointUPS.mos\
ModelicaTest.MultiBody.Joints.JointSSR.mos\
ModelicaTest.MultiBody.Joints.JointUSR.mos\
ModelicaTest.MultiBody.Joints.JointRRR.mos\
ModelicaTest.MultiBody.Joints.JointRRP.mos\
ModelicaTest.MultiBody.Joints.JointSSP.mos\
ModelicaTest.MultiBody.Joints.Planar.mos \
ModelicaTest.MultiBody.Joints.Prismatic.mos \
ModelicaTest.MultiBody.Joints.PrismaticInit.mos\
ModelicaTest.MultiBody.Joints.FreeMotion2.mos\
ModelicaTest.MultiBody.Joints.Revolute2.mos\
ModelicaTest.MultiBody.Joints.Spherical.mos \
ModelicaTest.MultiBody.Joints.SphericalSpherical.mos \
ModelicaTest.MultiBody.Joints.Universal.mos \
ModelicaTest.MultiBody.FourbarVariants.JointUSR_init.mos \


# Failing Tests:
#SphericalDoublePendulum - goes into infinite loop during simulation, precisely during initialisation of simulation
#InitializationConversion.Joints - goes in infinite loop
#ModelicaTest.MultiBody.Forces.SpringDamperParallel - Division by zero
#ModelicaTest.MultiBody.Forces.SpringDamperSeries - division by zero
#ModelicaTest.MultiBody.Joints.RevolutePlanarLoopConstraint - infinite loop
#ModelicaTest.MultiBody.Joints.SphericalSpherical2.mos - infinite loop
#ModelicaTest.MultiBody.Joints.UniversalSpherical.mos - infinite loop

FAILINGTESTFILES=\
ModelicaTest.MultiBody.SphericalDoublePendulum.mos \
ModelicaTest.MultiBody.InitializationConversion.Joints.mos \
ModelicaTest.MultiBody.Forces.SpringDamperParallel.mos\
ModelicaTest.MultiBody.Forces.SpringDamperSeries.mos\
ModelicaTest.MultiBody.Joints.UniversalSpherical.mos\
ModelicaTest.MultiBody.Joints.RevolutePlanarLoopConstraint.mos\
ModelicaTest.MultiBody.Joints.SphericalSpherical2.mos\
ModelicaTest.MultiBody.Joints.JointUPS2.mos \
ModelicaTest.MultiBody.Joints.JointUSP2.mos \

#WRONG resuts tests

#JointUSR - different result from Dymola, wrong initialisation of state derivative (j2.a)
#JointSSR - different result from Dymola, wrong initialisation of state derivative (j2.a)
#ModelicaTest.MultiBody.Forces.Damper2.mos
$(WRONGRESULTTEST)=\
ModelicaTest.MultiBody.FourbarVariants.JointUSR.mos \
ModelicaTest.MultiBody.FourbarVariants.JointSSR.mos \
ModelicaTest.MultiBody.Forces.Damper2.mos\


#$(NOTCOMPILETEST) \
#$(NOTSIMULATETEST) \

NOTCOMPILETEST= \

NOTSIMULATETEST= \

WRONGRESULTTEST = \


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
	
