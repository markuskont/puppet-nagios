require 'open3'

def parseEnclosureInfo(utility,hash)
  cmd = "#{utility} -EncInfo -AAll"
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    while line = stdout.gets
      if /Number of enclosures on adapter (\d+) -- (\d+)/.match(line)
        adapter = 'A' + $1
        hash[adapter] = {}
        #hash[adapter]['enclosure_count'] = $2
      elsif /Enclosure (\d+):/.match(line)
        enclosure = 'Enclosure' + $1
        hash[adapter][enclosure] = {}
      elsif /^\s*(.+)\s*:\s*(\S+)/.match(line)
        hash[adapter][enclosure][$1.strip().tr(" ","_")] = $2
      else
        # reset keys here
        # whitespace delimits enclosure info block
        next
      end
    end
  end
  return hash
end

def parseLogicalDriveInfo(utility,hash)
  hash.each do |key, value|
    cmd = "#{utility} -LDInfo -LAll -#{key}"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        if /Adapter \d+ -- Virtual Drive Information:/.match(line)
          next
        elsif /Virtual Drive: (\d+) \(Target Id: \d+\)/.match(line)
          vd = 'L' + $1
        end
      end
    end
  end
end

Facter.add(:megaraid_arrays) do
  confine :kernel => 'Linux'
  confine :is_virtual => false
  blockdevs = Facter.value(:blockdev_drivers)
  if blockdevs['megaraid_sas']
    megacli = `which megacli`
    megacli = megacli.chop
    if megacli
      setcode do
        getAdapters
      end
    end
  end
end