#!/usr/bin/env python
import os, sys, re, argparse, subprocess

def parseArguments():
  parser = argparse.ArgumentParser()
  parser.add_argument('-b', '--binary', default='/usr/sbin/megacli', help='Binary used for checking RAID status. By default /usr/sbin/megacli')
  args = parser.parse_args()
  return args

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

def getAdapters():
  adapters = []
  getAdpNmbr = re.compile('\s*Number of enclosures on adapter (\d+) -- \d+')
  try:
    enclosure_info = subprocess.Popen(['sudo', MEGACLIBIN, '-EncInfo', '-AAll'], stdout=subprocess.PIPE)
  except:
    nagiosReturn(3, "Unable to gather adapter info")
  for line in enclosure_info.stdout:
    if getAdpNmbr.match(line):
      adapters.append(getAdpNmbr.match(line).group(1))
  return adapters

def getLdStatus(adapters):
  for a in adapters:
    a = "-A%s" % a
    try:
      ld_info = subprocess.Popen(['sudo', MEGACLIBIN, '-LDInfo', '-LAll', a], stdout=subprocess.PIPE)
    except:
      nagiosReturn(3, "Unable to gather logical device info for adapter %s")
    for line in ld_info.stdout:
      print line,
  return ld_info

# GLOBAL VARIABLES
MEGACLIBIN = parseArguments().binary

def main():

  if not os.path.isfile(MEGACLIBIN):
    message = "Unable to find megacli binary in %s" % (MEGACLIBIN)
    nagiosReturn(3, message)
  else:
    adapters = getAdapters()
  getLdStatus(adapters)

if __name__ == "__main__":
  main()