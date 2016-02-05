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
  nagios_status = {}
  code = 0
  message = ''
  regex_ld = re.compile('Virtual Drive: (\d+)')
  regex_state = re.compile('State\s*:\s*(\w+)')
  for a in adapters:
    message = message + ' Adp: ' + a
    opt = "-A%s" % a
    try:
      ld_info = subprocess.Popen(['sudo', MEGACLIBIN, '-LDInfo', '-LAll', opt], stdout=subprocess.PIPE)
    except:
      nagiosReturn(3, "Unable to gather logical device info for adapter %s")
    for line in ld_info.stdout:
      if regex_state.match(line):
        status = regex_state.match(line).group(1)
        message = message +' State: ' + status
        if status != 'Optimal':
          code = 2
      elif regex_ld.match(line):
        message = message +' LD: ' + regex_ld.match(line).group(1)
        #print line,
  nagios_status['code'] = code
  nagios_status['message'] = message
  return nagios_status

# GLOBAL VARIABLES
MEGACLIBIN = parseArguments().binary

def main():

  if not os.path.isfile(MEGACLIBIN):
    message = "Unable to find megacli binary in %s" % (MEGACLIBIN)
    nagiosReturn(3, message)
  else:
    adapters = getAdapters()
    ld_info = getLdStatus(adapters)
    nagiosReturn(ld_info['code'], ld_info['message'])

if __name__ == "__main__":
  main()