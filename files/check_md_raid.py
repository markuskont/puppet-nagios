#!/usr/bin/env python
import os, sys, re, argparse

def nagiosReturn(code, message):

  if code == 0:
    print "OK - %s" % message
    sys.exit(code)
  elif code == 1:
    print "WARNING - %s" % message
    sys.exit(code)
  elif code == 2:
    print "CRITICAL - %s" % message
    sys.exit(code)
  elif code == 3:
    print "UNKNOWN - %s" % message
    sys.exit(code)
  else:
    print "UNKNOWN - internal error"
    sys.exit(3)

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('-d', '--device', help='Device node definition, e.g md1')
  parser.add_argument('-s', '--statfile', default='/proc/mdstat', help='File containing raid stats. By default /proc/mdstat')
  args = parser.parse_args()

  if args.device is None:
    nagiosReturn(3, "--device argument must be defined. Refer to -h or --help")

  try:
    f = open(args.statfile, 'r')
  except:
    nagiosReturn(3, "Unable to open mdadm stat file")

  for line in f:
    if line.startswith(args.device):
      # Disk membership is usually on next line
      # rebuild prgress is usually on the one after that
      # http://stackoverflow.com/questions/13572062/python-for-loop-with-files-how-to-grab-the-next-line-within-forloop
      for _ in xrange(2):
        try:
          line = f.next()
        except:
          nagiosReturn(3, "Unable to grab subsequent lines after identifying device")

        # move this to another functions
        # iterate a hash of possible scenarios
        if re.match('.*_.*', line):
          nagiosReturn(2, "Missing devices in array")
        elif re.match('recovery', line):
          nagiosReturn(1, "Array in RECOVERY")
        elif re.match('resync', line):
          nagiosReturn(1, "Array in RESYNC")
        elif re.match('check', line):
          nagiosReturn(1, "Array in CONSISTENCY CHECK; System may be slower than usual")
        else:
          nagiosReturn(0, "No issues detected")

if __name__ == "__main__":
  main()