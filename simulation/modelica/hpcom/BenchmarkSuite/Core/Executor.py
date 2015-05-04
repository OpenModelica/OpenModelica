'''
Created on 13.10.2013

@author: Marcus
'''
from Config import MoScript, Executable
from subprocess import Popen,PIPE
import psutil

class ExecutableExecutor(object):
    
    @staticmethod
    def execute(executable, pathToWorkDir):
        assert isinstance(executable, Executable)
        
        argString = ""

        for i in executable.arguments:
            argString = argString + " " + i
        
        process = Popen(executable.commandName + argString, cwd=pathToWorkDir, stdout=PIPE)
        p = psutil.Process(process.pid)
        p.nice = psutil.HIGH_PRIORITY_CLASS
        outString, _ = process.communicate()
        
        return outString

class MoScriptExecutor(object):
    
    @staticmethod
    def execute(script, pathToWorkDir):
        assert isinstance(script, MoScript)
        
        sim = Executable(commandName='omc', arguments=[script.fileName], workingDirectory=pathToWorkDir)
        return ExecutableExecutor.execute(sim, pathToWorkDir)