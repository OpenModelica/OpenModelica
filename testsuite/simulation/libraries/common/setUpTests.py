#-------------------------------------------------------------------------------
# Name:        testbuilder
# Purpose:
#
# Author:      Christian Schubert and Bruno Scaglioni
#
# Created:     14/02/2013
# Copyright:   (c) Bruno Scaglioni 2013 / christian schubert 2012
# Licence:     OSMC-PL 1.2 http://openmodelica.org/osmc-pl/osmc-pl-1.2.txt
#-------------------------------------------------------------------------------

import subprocess
import shutil
import os
import re
import OMPython

DYMOLA_EXECUTABLE = 'C:/Program Files/Dymola 2013 FD01/bin/dymola.exe'
OPENMODELICAHOME = os.environ['OPENMODELICAHOME']
OPENMODELICALPATH = os.environ['OPENMODELICALIBRARY']
OMLIBRARY = "%s/Modelica 3.2.1/package.mo"%OPENMODELICALPATH
SERVICELIBRARY= "%s/ModelicaServices 3.2.1/package.mo"%OPENMODELICALPATH

testkeywords='simulation MSL Examples'

#for OMpython
MSLVERSION='3.2.1'

#Absolute path of extra libraries
EXTRALIB=[]
REFFILESDIR='./ReferenceFiles'

log_file='testCreationlog.txt'
#
simulationTests = [
'Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulumInitTip', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.ForceAndTorque', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.FreeBody', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.HeatLosses', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.InitSpringConstant', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.LineForceWithTwoMasses', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.PendulumWithSpringDamper', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravity', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.PointGravityWithPointMasses2', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheel', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetDriving', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetPulling', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.SpringDamperSystem', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.SpringMassSystem', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.SpringWithMass', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.Surfaces', \
'Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings', \
'Modelica.Mechanics.MultiBody.Examples.Constraints.ConstrainPrismaticJoint', \
'Modelica.Mechanics.MultiBody.Examples.Constraints.ConstrainRevoluteJoint', \
'Modelica.Mechanics.MultiBody.Examples.Constraints.ConstrainUniversalJoint', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Engine1b_analytic', \
'Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6', \
'Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar1', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar2', \
'Modelica.Mechanics.MultiBody.Examples.Loops.Fourbar_analytic', \
'Modelica.Mechanics.MultiBody.Examples.Loops.PlanarLoops_analytic']
#'Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.ActuatedDrive', \
#'Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GearConstraint', \
#'Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.GyroscopicEffects', \
#'Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.MovingActuatedDrive', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.Components.GearType2', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.Components.MechanicalStructure', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.Components.PathPlanning1', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.Components.PathPlanning6', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.Components.PathToAxisControlBus', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.fullRobot', \
#'Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.oneAxis']

#simulationTests = ['Modelica.Mechanics.MultiBody.Examples.Rotational3DEffects.ActuatedDrive']
                   
class Kind:
    Instantiation,Translation,Compilation,SuppressedSimulation,SimpleSimulation,VerifiedSimulation= range(6)
    
def testingString(type):
    if type==Kind.Instantiation:return 'OpenModelicaModelTesting.Kind.Instantiation'
    if type==Kind.Translation:return 'OpenModelicaModelTesting.Kind.Translation'    
    if type==Kind.Compilation:return 'OpenModelicaModelTesting.Kind.Compilation'
    if type==Kind.SuppressedSimulation:return 'OpenModelicaModelTesting.Kind.SuppressedSimulation'
    if type==Kind.SimpleSimulation:return 'OpenModelicaModelTesting.Kind.SimpleSimulation'
    if type==Kind.VerifiedSimulation:return 'OpenModelicaModelTesting.Kind.VerifiedSimulation'
    
def findStateSet(model):
    mosFile='tempMos.mos'
    f=open(mosFile,'w')
    f.write('loadModel(Modelica,{"3.2.1"});\n')
    
    if EXTRALIB:
        for lib in EXTRALIB:
            lib=lib.replace('\\','/')
            f.write('loadFile("%s");\n'%lib)
    f.write('setMatchingAlgorithm("PFPlusExt");\nsetIndexReductionMethod("dynamicStateSelection");\nsetDebugFlags("scodeInstShortcut");\n')
    f.write('translateModel(%s);\n'%model)
    f.write('getErrorString();\n')
    f.close()
    
    try:
        ret = subprocess.check_output([OPENMODELICAHOME + '/bin/omc.exe', mosFile, '+d=backenddaeinfo,stateselection'])
        ret = ret.replace('\r\n', '\n')
    except subprocess.CalledProcessError as cpe:
        print('Error: states identification failed for model %s'%model)
        return
    
    BEGIN_STATES = "selected States: "
    END_STATES = '\n'
    begin = ret.find(BEGIN_STATES)
    if (begin >= 0):
        begin = begin + len(BEGIN_STATES)
        end = ret.find(END_STATES, begin)
        if (end >= 0):
            states = ret[begin:end]
            if states:
                states = states.split(', ')
            else: 
                states=None
    return states
    
        
def replaceInFile(fileName, varName, value):
       
        if not isinstance(varName, (tuple,list)):
            varName = [varName]
        if not isinstance(value, (tuple,list)):
            value = [value]

        assert len(value) == len(varName)

        # Read Template
        f = open(fileName, 'r')
        content = f.read()
        f.close()

        # Change variable
        for i in xrange(len(varName)):
            content = content.replace('$' + varName[i] + '$', value[i])

        # Save Template
        f = open(fileName, 'w')
        f.write(content)
        f.close()

def getExamples(lib):
    mosFile = 'getExamples.mos'
    resFile = os.path.join(os.path.abspath(os.path.curdir),'models.txt')
    # get a proper escaped string
    resFile = resFile.replace('\\', '/')

    if not (os.path.exists(resFile)):
        print( "Could not find %s. Fetching all examples from Dymola"%resFile)

        # --- Generate mos file ---
        f = open(mosFile, 'w')
        f.write('openModel("printModels.mo");\n')
        f.write('openModel("traversePackage.mo");\n')
        f.write('openModel("%s");\n'%LIBRARY)
        f.write('traversePackage("Modelica");\n')
        f.write('savelog("%s");\n'%resFile)
        f.write('exit();\n')
        f.close()

        # --- Run Dymola ---
        try:
            subprocess.call([DYMOLA_EXECUTABLE, mosFile])
        except subprocess.CalledProcessError as cpe:
            print( "Could not run Dymola to get all examples")
            exit()

    # --- read result file ---
    f = open(resFile, 'r')
    content = f.read()
    f.close()

    # extract models
    begin = content.find('traversePackage(')
    assert begin >= 0
    begin = content.find(';\n', begin)
    assert begin >= 0
    begin = begin + 2   # go past ';\n'
    end = content.rfind('\nsavelog("')
    assert end >= begin

    # extract, split and return them
    models = content[begin:end]
    models = models.split('\n')
    return models

def generateRefFiles(tests):
    # --- 1. Generate ref-files using dymola ---
    dymola_mos_file = 'dymola_ref.mos'
    absPath = os.path.abspath(os.path.curdir)
    absPath=absPath.replace('\\','/')
    dymola_res_file = os.path.join(absPath,'dymola_ref_log.txt')
    # get a proper escaped string
    dymola_res_file = dymola_res_file.replace('\\', '/')
    f = open(dymola_mos_file, 'w')
    
    f.write('clear();\n')
    f.write('openModel("%s");\n'%OMLIBRARY)
    f.write('openModel("%s");\n'%SERVICELIBRARY)
    
    if EXTRALIB:
        for lib in EXTRALIB: f.write('openModel("%s");\n'%lib)
        
    f.write("system(\"clean.cmd\");\n");
    f.write('cd("%s");\n'%absPath);
    empty=True;
    for modelName in tests:
        refFile = os.path.join(os.path.abspath(REFFILESDIR),modelName)
        if not os.path.exists(refFile+".mat"):
            empty = False
            f.write('modelName="%s";\n'%(modelName))
            f.write('translateModel(modelName);\n')
            f.write('simulate();\ncommand="ren dsres.mat "+modelName+".mat";\nsystem(command);\n')
    f.write('savelog("%s");\n'%dymola_res_file)
    f.write('exit();\n')
    f.close()

    # run dymola to generate reference files
    try:
        if (not empty):
            print("Generating ref-files")
            subprocess.call([DYMOLA_EXECUTABLE, dymola_mos_file])
    except subprocess.CalledProcessError as cpe:
        print("Generating ref-files with Dymola failed!")
    #move all generated file to ../ReferenceFiles/
    
    if not empty:
        for modelName in tests:
            refFile = os.path.join(os.path.abspath(REFFILESDIR),modelName)
            if not os.path.exists(refFile+".mat"):
                resFile = '%s/%s.mat'%(absPath,modelName)
                shutil.move(resFile,os.path.abspath(REFFILESDIR))
    return

def main():

    # get all tests
    # license problem, if you don't have ModelManagement license on dymola this won't work.
    #Trying to find a solution
    #missingTests = getExamples(OMLIBRARY)
    for i in simulationTests:
        if i.endswith('.mos'): 
            simulationTests[simulationTests.index(i)]=i[:i.rfind('.mos')]

    # generate ref files
    generateRefFiles(simulationTests)

    # go one folder up, now I should be in the folder where tests must be put
    absPath = os.path.abspath(os.path.curdir);
    
    logFile=open(log_file,'w')
    
    # select kind of test for each model.
    OMPython.execute("clear()")
    command='loadModel(Modelica,{"%s"})'%MSLVERSION
    res=OMPython.execute(command)
    if not res:
        print('Loading modelica library failed')
        return
    
    if EXTRALIB:
        for lib in EXTRALIB:
            lib=lib.replace('\\','/')
            res=OMPython.execute('loadFile("%s")'%lib)
            if not res:
                print('Loading library %s failed'%lib)
    # build a dictionary containing the list of tests to be created and the kind of functionality to be tested
    
    #the dictionary
    TestingType={}
    logFile.write('List of models tested with test kind\n')
    for modelName in simulationTests:

        # do not run tests, where no ref file exists
        refFile = '%s/ReferenceFiles/%s.mat'%(absPath,modelName)
        if not (os.path.exists(refFile)):
            logFile.write("Skipping %s because there is no ref-file\n"%modelName)
            continue
        
        # do not run tests, that have already been set up
        mos=modelName+'.mos'
        if (os.path.exists(mos)):
            logFile.write("Skipping %s because mos-File already exists\n"%modelName)
            continue

        print('Analyzing the current status of %s'%modelName)
        
        command='simulate(%s)'%modelName
        #try to simulate
        res=OMPython.execute(command)
        
        resultMess=res['SimulationResults']['messages']
        
        if  res['SimulationResults']['resultFile']<>'""':
            #if an output file exists we should check results but still have to think on how to do it
            if resultMess=='""':
                TestingType[modelName]=Kind.VerifiedSimulation
                logFile.write('%s : VerifiedSimulation\n'%modelName)
                continue
        #else if i simulate with messages
            else:
                TestingType[modelName]=Kind.SuppressedSimulation
                logFile.write('%s : SuppressedSimulation\n'%modelName)
                continue
        #if there is no result file 
        else:
            command='buildModel(%s)'%modelName
            commandtransl='translateModel(%s)'%modelName
            res=OMPython.execute(command)
            if res['SET1']['Values'][0]<>'"",""':
                TestingType[modelName]=Kind.SuppressedSimulation
                logFile.write('%s : SuppressedSimulation\n'%modelName)
                continue
            elif OMPython.execute(commandtransl):
                TestingType[modelName]=Kind.Compilation
                logFile.write('%s : Compilation\n'%modelName)
                continue
            else:
                command='instantiateModel(%s)'%modelName
                res=OMPython.execute(command)
                if res<>'""\n':
                    TestingType[modelName]=Kind.Translation
                    logFile.write('%s : Translation\n'%modelName)
                    continue
                else:
                    TestingType[modelName]=Kind.Instantiation
                    logFile.write('%s : Instantiation\n'%modelName)
                    continue
#now we have the tests list AND the functionality to be tested for each test now I have to generate the file
    warnings=False
    logFile.write('\n\nWarnings:\n\n')
    for model,test in TestingType.iteritems():
        
        if test==Kind.Instantiation:
            stateset='';
        else:
            stateset=findStateSet(model)
            if not stateset:
                logFile.write('Could not find states for test %s, moving test to simple simulation\n'%model)
                TestingType[model]=Kind.SimpleSimulation
                test=Kind.SimpleSimulation
                stateset='""'
            else:    
                stateset=[i for i in stateset if i.find('STATESET')==-1] 
                stateset='"'+'","'.join(stateset)+'"'
        
        mosTest='%s.mos'%model
        print('creating %s'%mosTest)
        shutil.copy('../Common/Template.mos', mosTest)
        
        replaceInFile(mosTest,['testingType','modelName','states'],[testingString(test),model,stateset])
        ret = subprocess.check_output([OPENMODELICAHOME + '/bin/omc.exe', mosTest])
        ret=' '+ret.replace('\r\n','\n// ')
        ret=ret[:ret.rfind('\n// ')]
        #erase current directory from paths
        ret=ret.replace(absPath.replace('\\','/')+'/','')
        if ret.find('Files not Equal')>-1:
            logFile.write('Warning: %s output not equal to reference file\n'%model)
            warnings=True
        #header does not begin with comment statement because is alredy in the file
        header=' name: %s\n'%model
        header=header + '// keywords: %s\n'%testkeywords
        header=header + '// status: correct\n//\n// Simulation Results\n// Modelica Standard Library\n//\n'
        replaceInFile(mosTest,['header','footer'],[header,ret])
        print('test case for model:%s created!'%model)
    #clean directory
    subprocess.call([absPath+'/cleanAllbutMat.cmd'])
    print('Finished! check files before uploading')
    if warnings:
        print('There are warnings, check the log file')
    logFile.close()

if __name__ == '__main__':
    main()
