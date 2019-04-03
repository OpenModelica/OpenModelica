'''
Created on 13.10.2013

@author: Marcus
'''

class Executable(object):
    
    @property
    def commandName(self):
        return self.__commandName

    @commandName.setter
    def commandName(self,value):
        self.__commandName = value

    @property
    def arguments(self):
        return self.__arguments

    @arguments.setter
    def arguments(self,value):
        self.__arguments = value

    @property
    def workingDirectory(self):
        return self.__workingDirectory

    @workingDirectory.setter
    def workingDirectory(self,value):
        self.__workingDirectory = value

    def __init__(self, commandName='', arguments=[], workingDirectory='.'):
        self.__commandName = commandName
        self.__arguments = arguments
        self.__workingDirectory = workingDirectory
        
        
class MoScript(object):
    
    @property
    def fileName(self):
        return self.__fileName
    
    @fileName.setter
    def fileName(self,value):
        self.__fileName = value
    
    @property
    def useHpcOm(self):
        return self.__useHpcOm
    
    @useHpcOm.setter
    def useHpcOm(self,value):
        self.__useHpcOm = value
    
    @property
    def numberOfCores(self):
        return self.__numberOfCores
    
    @numberOfCores.setter
    def numberOfCores(self, value):
        self.__numberOfCores = value
        
    @property
    def hpcomScheduler(self):
        return self.__hpcomScheduler
    
    @hpcomScheduler.setter
    def hpcomScheduler(self,value):
        self.__hpcomScheduler = value
        
    @property
    def additionalInfo(self):
        return self.__additionalInfo
    
    @additionalInfo.setter
    def additionalInfo(self, value):
        self.__additionalInfo = value
        
    def __init__(self, fileName='', useHpcOm=False, numberOfCores=1, hpcomScheduler='', additionalInfo=''):
        self.__fileName = fileName
        self.__useHpcOm = useHpcOm
        self.__numberOfCores = numberOfCores
        self.__hpcomScheduler = hpcomScheduler
        self.__additionalInfo = additionalInfo
        
    def __str__(self, *args, **kwargs):
        return 'file: ' + self.__fileName + ' hpcom: ' + str(self.__useHpcOm) + ' numberOfCores: ' + str(self.__numberOfCores) + ' hpcomScheduler: ' + str(self.__hpcomScheduler) + ' addInfo: ' + str(self.__additionalInfo)