def discover_blockdevs
  bdevs = []
  Dir.glob("/sys/block/sd?") do |path|
    bdevs << BlockInfo.new(path[/sd./])
  end
  Dir.glob("/sys/block/md?") do |path|
    bdevs << BlockInfo.new(path[/md./])
  end
  Dir.glob("/sys/block/cciss!c?d?") do |path|
    bdevs << BlockInfo.new(path[/cciss!..../].sub(/!/, "_"))
  end
  return bdevs
end

Facter.add(:linux_softraid_arrays) do
  confine :kernel => 'Linux'
  setcode do
    bdevs = []
    #results = {}
    #disks = Facter.value(:disks)
    #results = disks
    #disks.each do |device|
    #  results[count] = device
    #  count++
    #end
    Dir.glob("/sys/block/md?") do |path|
      bdevs << BlockInfo.new(path[/md./])
    end
    bdevs
  end
end