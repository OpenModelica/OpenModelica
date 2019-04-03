#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      Schubert
#
# Created:     12.11.2012
# Copyright:   (c) Schubert 2012
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import os
import glob
import shutil

NOGROUP = '_NoGroup'

# GroupName, Words that must occur, Words that must not occur
Groups = [('_Flattening', 'Error occurred while flattening model', None), \
          ('_Expression', 'Failed to elaborate expression', None), \
          ('_Nonlinear', 'Error solving nonlinear system', None), \
		      ('_Mixed', 'Your model contains a mixed system involving algorithms', None), \
          ('_Initialization_convert', 'convertInitialResidualsIntoInitial', None), \
          ('_Initial_Under', 'It was not possible to solve the under-determined initial system', None), \
          ('_Initial_Over', 'It was not possible to solve the over-determined initial system', None), \
          ('_Initial_NotUnique', 'Internal error It is not possible to determine unique', None), \
          ('_Initialization', 'Error in initialization', None), \
          ('_Initialization', 'The number of initial equations are not consistent with the number of unfixed variables', None), \
          ('_Backend', 'Internal error Transformation Module', None), \
          ('_Backend', 'Internal error IndexReduction.', None), \
          ('_DivByZero', 'division by zero', None), \
          ('_CodeGen', 'Error building simulator', None), \
          ('_Unbalanced', 'Too many equations, overdetermined system', None), \
          ('_Unbalanced', 'Too few equations, underdetermined system', None), \
          ('_SimFailed', 'Simulation failed for model', None), \
          ('_IntegratorFailed', 'Integrator failed', None), \
		      ('_TableBug', ['n Table: NoName from File: NoName with Size', 'try to get', 'out of range!'], None), \
          ('_SimExecFailed', 'Simulation execution failed for model', None), \
          ('_UnknownVar', ['Get Data of Var', 'from file', 'failed'], None), \
          ('_NotEqual', 'Files not Equal!', None), \
          ('_OK', 'Files Equal!', 'failed')]

def checkFile(fileName, groups):

    # Check File Size first (ignore > 128Kb)
    if (os.path.getsize(fileName) > 128*1024):
        print "Skipping %s. Because file is too large!"%fileName
        return NOGROUP

    # Open, Read and Close file
    f = open(fileName, 'r')
    content = f.read()
    f.close()

    # run through all groups
    for g in groups:
        groupName = g[0]
        include = g[1]
        exclude = g[2]
        if (include is None): include = list()
        if (not isinstance(include, (list,tuple))): include = [include]
        if (exclude is None): exclude = list()
        if (not isinstance(exclude, (list,tuple))): exclude = [exclude]

        # test for include
        found = True
        for i in include:
            if (content.find(i) < 0):
                found = False
                break
        if (found == False): continue

        # test for exclude
        found = False
        for e in exclude:
            if (content.find(e) >= 0):
                found = True
                break
        if (found == True): continue

        # we found the group
        return groupName

    # we did not find a matching group
    return None

def main():

    stat = dict()
    models = dict()

    # set up folders
    if (os.path.exists(NOGROUP)):
        shutil.rmtree(NOGROUP)
    os.mkdir(NOGROUP)

    for g in Groups:
        groupName = g[0]
        pathName = os.path.join(os.curdir, groupName)
        if (os.path.exists(pathName)):
            shutil.rmtree( pathName )
        os.mkdir( pathName )

    # get all ".mos.txt" files in folder
    files = glob.glob( os.path.join(os.curdir, '*.mos.txt') )
    for fileName in files:

        # get group for file
        groupName = checkFile(fileName, Groups)

        # no group found
        if groupName is None: groupName = NOGROUP

        # copy file to group
        splitName = os.path.split(fileName)
        path = os.path.join(os.curdir, groupName)
        newFileName = os.path.join(path,splitName[1])
        shutil.copyfile(fileName, newFileName)

        # count
        try:
            stat[groupName] = stat[groupName] + 1
        except:
            stat[groupName] = 1

        # log
        try:
            models[groupName].append(splitName[1])
        except:
            models[groupName] = [splitName[1]]

    # delete folders if empty
    for g in Groups:
        groupName = g[0]
        pathName = os.path.join(os.curdir, groupName)
        if (not (groupName in stat.keys())) and (os.path.exists(pathName)):
            os.rmdir( pathName )


    # Finished
    print "**** Statistics ****"
    print "%i models in total"%len(files)
    for k,v in sorted(stat.items()):
        groupName = k.replace('_', '')
        print "%s:\t%i"%(groupName,v)


    print "\n**** Details - groupwise ****"
    for k,v in sorted(models.items()):
        groupName = k.replace('_', '')
        print "%s (%i):"%(groupName, len(v))
        for m in sorted(v):
            modelName = m.replace('.mos.txt', '')
            print "\t%s"%modelName

    # Inverse Mapping
    inv_map = {}
    for k, v in models.iteritems():
        groupName = k.replace('_', '')
        for m in v:
            modelName = m.replace('.mos.txt', '')
            inv_map[modelName] = groupName

    print "\n**** Details - modelwise ****"
    for k,v in sorted(inv_map.items()):
        print "%s -> %s"%(k, v)

if __name__ == '__main__':
    main()
