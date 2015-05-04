'''
Created on 13.10.2013

@author: Marcus
'''

from Config import MoScript
import re
import shutil

class ScriptPreHandler(object):
    
    def handle(self, script, pathToWorkDir):
        assert isinstance(script, MoScript)
        
        #Set the hpcom-commands in the mos-file correctly
        modificator = HpcomMosFileModificator(filePath=pathToWorkDir + '/' + script.fileName)
        if(script.useHpcOm):
            modificator.enableHpcom(script.numberOfCores, script.hpcomScheduler)
        else:
            modificator.disableHpcom()
            
        #Copy the right external-graph
        if(script.hpcomScheduler == 'ext'):
            shutil.copyfile(pathToWorkDir + script.additionalInfo + '_' + str(script.numberOfCores) + '_ext.graphml', pathToWorkDir + script.additionalInfo + '.graphml')
        
class HpcomMosFileModificator(object):
    @property
    def filePath(self):
        return self.__filePath

    @filePath.setter
    def filePath(self, value):
        self.__filePath = value

    def __init__(self, filePath=''):
        self.__filePath = filePath
        self.__hpcomPattern = re.compile("setDebugFlags\(\"hpcom\"\);[ ]*getErrorString\(\);\nsetCommandLineOptions\(\"\+n=[0-9]+ \+hpcomScheduler=[^\"]*\"\); getErrorString\(\);\n")
        self.__simulatePattern = re.compile("simulate\([^\)]*\);[ ]*getErrorString\(\);\n")
        self.__inlinePattern = re.compile("setDebugFlags\(\"hpcomInlineTasks\"\);[ ]*getErrorString\(\);\n")

    def enableHpcom(self, numberOfCores=1, hpcomScheduler=''):
        if(self.isHpcomEnabled()):
            self.disableHpcom()
        
        fileContent = self.__readFile()
        match = self.__simulatePattern.search(fileContent)
        if(match == None):
            raise Exception("Couldn't find  the simulation-command in file.")

        out = self.__simulatePattern.sub("setDebugFlags(\"hpcom\"); getErrorString();\nsetCommandLineOptions(\"+n=" + str(numberOfCores) + " +hpcomScheduler=" + str(hpcomScheduler) + "\"); getErrorString();\n" + (match.string[match.start():match.end()]), fileContent)
        self.__writeFile(out)

    def disableHpcom(self):
        if(self.isHpcomEnabled()):
            fileContent = self.__readFile()
            match = self.__hpcomPattern.search(fileContent)
            if(match == None):
                raise Exception("Couldn't find the hpcom-command in file.")

            out = self.__hpcomPattern.sub("", fileContent)
            self.__writeFile(out)

    def isHpcomEnabled(self):
        fileContent = self.__readFile()
        match = self.__hpcomPattern.search(fileContent)
        return (match != None)

    def __readFile(self):
        f = open(self.__filePath, 'r')
        return f.read()

    def __writeFile(self, value):
        f = open(self.__filePath, 'w')
        return f.write(value)