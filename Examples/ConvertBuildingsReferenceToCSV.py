# Converts the buildings .txt format to equidistant csv-files

import os
import sys
from optparse import OptionParser

def convertDir(indir,outdir):
  for fil in os.listdir(indir):
    print "Converting file: %s\n" % indir+"/"+fil
    with open(indir+"/"+fil) as f:
      v = {}
      for line in f.readlines():
        line = line.strip().split('=')
        # print "Line %s \n" % line
        if (line is not None) and (len(line) == 2) and (line[1] != ''):
          if (line[1][0] == '['):
            l = [str(float(s)) for s in line[1].strip('[]').split(',')]
            if len(l)==2:
              diff = float(l[1])-float(l[0])
              l = [str(float(l[0])+x*diff) for x in range(101)]
            if len(l)<>101:
              raise Exception("Assumed buildings result format has exactly 101 data points")
            v[line[0]] = l
      keys = v.keys()
      keys.remove('time')
      keys.sort()
      keys = ['time'] + keys
      values = [v[key] for key in keys]
      # Transpose
      rows = map(list, zip(*values))
      o = open(outdir+"/"+fil[0:-4]+'.csv', 'w')
      o.write(','.join(keys) + '\n')
      for row in rows:
        o.write(','.join(row) + '\n')

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
