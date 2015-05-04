'''
Created on 14.10.2013

@author: Marcus
'''
import re

class SimResultFilter(object):
    @staticmethod
    def checkIfFilesEqual(inString):
        simTimePattern = re.compile("Files Equal!")
        match = simTimePattern.search(inString)
        
        if(match == None):
            return False

        return True

    @staticmethod
    def checkIfTaskGraphCorrect(inString):
        simTimePattern = re.compile("Taskgraph correct")
        match = simTimePattern.search(inString)
        
        if(match == None):
            return False

        return True
    
class SimTimeFilter(object):
    @staticmethod
    def getFilterValue(inString):
        simTimePattern = re.compile("timeSimulation = [0-9]*\.[0-9]*")
        match = simTimePattern.search(inString)
        
        if(match == None):
            raise Exception("Couldn't find timeSimulation in given string.");

        return match.string[(match.start()+17):match.end()]
