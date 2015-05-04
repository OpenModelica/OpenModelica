#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      waurich
#
# Created:     14.11.2013
# Copyright:   (c) waurich 2013
# Licence:     <your licence>
#-------------------------------------------------------------------------------


# deletes all the stuff after simulation. exceptions can be added

import os
import string
import re
#############################################################################

#############################################################################
# the regular expressions that can be found in the filenames which shall not be deleted
regex = re.compile('_eqs_prof.json|_ext.graphml|_prof.json')

# file formats that will be deleted
fileFormats = ['exe','svg','plt','data','html','tmp','c','h','libs','makefile','csv','mat','o','log','dll','graphml','xml','realdata','intdata','exp']
#############################################################################
#functions
##########
def getFilesByFormat(listOfFiles,fileFormat,inLst):
    for i in listOfFiles:
        splittedString = i.split(".")
        if splittedString[-1] == fileFormat:
            inLst.append(i)
    return inLst
##########
def deleteFiles(delFormats):
    path = os.path.curdir
    allFiles = os.listdir(path)
    for form in fileFormats:
        files = getFilesByFormat(allFiles,form,[])
        for i in files:
            matches = re.search(regex,i)
            if matches == None:
                print i
                os.remove(i)
    return None
##########
def main():
    deleteFiles(fileFormats)
    return None
#############################################################################
if __name__ == '__main__':
    main()

