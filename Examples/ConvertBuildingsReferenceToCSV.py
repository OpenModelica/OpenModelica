# Converts the buildings .txt format to equidistant csv-files

import os
import sys
from optparse import OptionParser

########################################################################
# Adrian.Pop@liu.se                             2016-12-10
# parts of this script were taken from the building library here:
# https://github.com/lbl-srg/modelica-buildings/*/buildingspy_to_csv.py
########################################################################
# This script converts a reference result file
# from the format used by BuildingsPy to the
# csv format used by the Modelica Association.
#
# This script is provided for tools that compare the
# reference results with the csv compare tool
# from the Modelica Association.
#
# MWetter@lbl.gov                               2016-08-31
########################################################################

def _read_reference_result(file_name):
    ''' Read the reference results and write them as a csv file
        with the same base file name.

    :param file_name: The name of the reference file.
    :return: A dictionary with the reference results.

    This function is based on buildingspy.development.regressiontest:_readReferenceResults()
    but provided as a stand-alone function to avoid dependency on
    BuildingsPy.

    '''
    f=open(file_name,'r')
    lines = f.readlines()
    f.close()

    # Compute the number of the first line that contains the results
    iSta=0
    for iLin in range(min(2, len(lines))):
        if "svn-id" in lines[iLin]:
            iSta=iSta+1
        if "last-generated" in lines[iLin]:
            iSta=iSta+1

    # Dictionary that stores the reference results
    r = dict()
    iLin = iSta
    while iLin < len(lines):
        lin = lines[iLin].strip('\n')
        try:
            (key, value) = lin.split("=")
            # Check if this is a statistics-* entry.
            if key.startswith("statistics-"):
                while (iLin < len(lines)-1 and lines[iLin+1].find('=') == -1):
                    iLin += 1
            else:
                s = (value[value.find('[')+1: value.rfind(']')]).strip()
                numAsStr=s.split(',')
                val = []
                for num in numAsStr:
                    # We need to use numpy.float64 here for the comparison to work
#                    val.append(numpy.float64(num))
                    val.append(num)
                r[key] = val
        except ValueError as detail:
            s =  "%s could not be parsed.\n" % file_name
            sys.stderr.write(s)
            raise TypeError(detail)
        iLin += 1
    return r

def _write_csv(file_name, d):
    """ Writes the dictionary with the reference results to a csv file.

        :param file_name: The name of the csv reference file.
        :param: A dictionary with the reference results.
    """
    import numpy as np
    # Get the length of the data series

    # Check if time is a key, as FMU export has no time series
    found_time = False
    for key in d.keys():
        if key == 'time':
            found_time = True
            break
    if not found_time:
        return

    n = 2
    for key in d.keys():
        # Parameters and time have two entries. Hence, we search
        # to see if there are data with more entries.
        if len(d[key]) > 2:
            n = len(d[key])
            break
    # Set all series to have the same length
    for key in d.keys():
        if len(d[key]) != n:
            if key == 'time':
                d[key] = np.linspace( \
                   np.float64(d[key][0]), \
                   np.float64(d[key][-1]), n).tolist()
            else:
                d[key] = [d[key][0] for x in range(n)]

    # Write data as csv file
    with open(file_name, 'w') as f:
        # Write header
        f.write("time")
        for key in d.keys():
            if key != 'time':
                f.write(", %s" % key)
        f.write("\n")
        # Write data
        for i in range(n):
            vals = d['time']
            f.write(str(vals[i]))
            for key in d.keys():
                if key != 'time':
                    vals = d[key]
                    f.write(", %s" % vals[i])
            f.write("\n")


def convertDir(indir,outdir):
  for fil in os.listdir(indir):
    print "Converting file: %s\n" % indir+"/"+fil
    with open(indir+"/"+fil) as f:
      # skip FMU files!
      if 'statistics-fmu-dependencies' in f.read():
        print "... skipping FMU file\n"
        continue
      else:
        f.seek(0)
      d = _read_reference_result(indir+"/"+fil)
      _write_csv(outdir+"/"+fil[0:-4]+'.csv', d)

def main():
  parser = OptionParser()
  parser.add_option("--input-dir", help="Directory containing .txt reference files in the Buildings package format", type="string", dest="input_dir", default=os.path.abspath('.'))
  parser.add_option("--output-dir", help="Directory to generate csv-files in", type="string", dest="output_dir", default=os.path.abspath('.'))
  (options, args) = parser.parse_args()
  if len(args)<>0:
    parser.error('This program does not take positional arguments')
  convertDir(options.input_dir,options.output_dir)
if __name__ == '__main__':
    sys.exit(main())
