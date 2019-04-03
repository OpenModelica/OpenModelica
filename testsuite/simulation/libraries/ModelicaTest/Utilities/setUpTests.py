#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      Schubert
#
# Created:     18.10.2012
# Copyright:   (c) Schubert 2012
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import subprocess
import shutil
import os
import re

DYMOLA_EXECUTABLE = 'C:/Program Files/Dymola 2013/bin/dymola.exe'
OPENMODELICAHOME = os.environ['OPENMODELICAHOME']
OPENMODELICALIBRARY = os.environ['OPENMODELICALIBRARY']
LIBRARY = "%s/Modelica 3.2.1/package.mo"%OPENMODELICALIBRARY


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
        
        #Substitute carriage returns with comma
        for i in range(len(value)):
            value[i]=value[i].replace("\n",",\n")

        # Change variable
        for i in range(len(varName)):
            content = content.replace('$' + varName[i] + '$', value[i])
            
        # Save Template
        f = open(fileName, 'w')
        f.write(content)
        f.close()


def cleanOutput(s):
    # dummy output
    states = ""

    # Remove backendaeinfo
    BEGIN_INFO = 'No. of Equations'
    END_INFO = '##########'
    begin = s.find(BEGIN_INFO)
    end = s.rfind(END_INFO)
    if ((begin >= 0) and (end >= 0)):
        end = end+len(END_INFO)
        info = s[begin:end]
        s = s[:begin] + s[end+1:]

        # extract states
        BEGIN_STATES = "selected States: "
        END_STATES = "\n"
        begin = info.find(BEGIN_STATES)
        if (begin >= 0):
            begin = begin + len(BEGIN_STATES)
            end = info.find(END_STATES, begin-2)
            if (end >= 0):
                states = info[begin:end]
                states = states.split(', ')
                states = '"\n"'.join(states)

    # Remove Paths
    paths = re.findall('resultFile = "([^"]*)"', s)
    for p in paths:
        splitName = os.path.split(p)
        fileName = splitName[1]
        s = s.replace(p, fileName)

    # And all times
    s = re.sub('^[\s]*time[\w]+\s=\s[\d]+\.[\d]+,?\n', '', s, flags=re.MULTILINE)

    # remove last linebreak
    if (s.endswith('\n')):
        s = s[:-1]

    # remove last comma
    #s = s.replace('",\nend SimulationResult;', '"\nend SimulationResult;')

    # add comments
    s = re.sub(r'\n', r'\n// ', s)

    return (s, states)



def getExamples():
    mosFile = 'getExamples.mos'
    resFile = os.path.join(os.path.abspath(os.path.curdir),'models.txt')
    # get a proper escaped string
    resFile = resFile.replace('\\', '/')

    if not (os.path.exists(resFile)):
        print ("Could not find %s. Fetching all examples from Dymola"%resFile)

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
            print ("Could not run Dymola to get all examples")
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
    dymola_res_file = os.path.join(os.path.abspath(os.path.curdir),'dymola_ref_log.txt')
    # get a proper escaped string
    dymola_res_file = dymola_res_file.replace('\\', '/')
    f = open(dymola_mos_file, 'w')
    f.write('openModel("getStopTime.mo");\n')
    f.write('tmp = 1;\n')
    f.write('openModel("%s");\n'%LIBRARY)
    absPath = os.path.abspath(os.path.curdir)
    empty = True
    for modelName in tests:
        refFile = '%s/../ReferenceFiles/%s'%(absPath,modelName)
        if not os.path.exists(refFile + '.mat'):
            empty = False
            f.write('tmp = getStopTime("%s");\n'%(modelName))
            f.write('simulateModel("%s", stopTime=tmp, resultFile="%s");\n'%(modelName,refFile))
    f.write('savelog("%s");\n'%dymola_res_file)
    f.write('exit();\n')
    f.close()

    # --- 2. Run Dymola ---
    try:
        if (not empty):
            print ("Generating ref-files")
            subprocess.call([DYMOLA_EXECUTABLE, dymola_mos_file])
    except subprocess.CalledProcessError as cpe:
        print ("Generating ref-files with Dymola failed!")
        exit()



def main():

    # get all tests
    # missingTests = getExamples()

    missingTests = ['']
	
    # generate ref files
    #generateRefFiles(missingTests)

    # go one folder up
    os.chdir('..')
    absPath = os.path.abspath(os.path.curdir)

    # run through all missing tests
    for modelName in missingTests:

        print(modelName)

        # --- 1. Generate mos-File ----
        mosFile = '%s.mos'%modelName

        # do not run tests, that have already been set up
        if (os.path.exists(mosFile)):
           print ("Skipping %s because mos-File already exists"%modelName)
           continue

        shutil.copyfile( 'Utilities/Template.mos', mosFile )
        replaceInFile(mosFile, 'modelname', modelName)

        try:
            # --- 2. Run omc to generate result file ---
            ret = subprocess.check_output([OPENMODELICAHOME + '/bin/omc.exe','+d=backenddaeinfo,stateselection',mosFile])
            ret=str(ret)
            ret = ret.replace("\\r\\n","\n")

            # update mos file
            ret, states = cleanOutput(ret)
            replaceInFile(mosFile, 'simulation_output', ret)

            replaceInFile(mosFile, 'states', states)

            # --- Do not overwrite reffiles by Dymola ---
            #shutil.copyfile( '%s_res.mat'%modelName, '../ReferenceFiles/%s.mat'%modelName )

            if (ret.find("Simulation terminated") >= 0):
                print (" - Simulation terminated")
            else:
                if (ret.find("Files Equal!") >= 0):
                    print (" - OK")
                else:
                    print (" - Failed")
        except subprocess.CalledProcessError as cpe:
            # update simulation output
            s, states = cleanOutput(cpe.output)
            replaceInFile(mosFile, ['simulation_output', 'states'], [s, ''])
        except Exception as e:
            replaceInFile(mosFile, 'simulation_output', '// Translation failed.')
            print (' - Translation of %s failed.'%modelName)


if __name__ == '__main__':
    main()
