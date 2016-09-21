require 'open3'

Facter.add("email_server") do
  confine :kernel => 'Linux'
  hash = {}
  cmd = "which postfix sendmail"
  paths = []

  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    while line = stdout.gets
      paths << line.strip
    end
    hash['path'] = paths if paths.size > 0
  end
  if ( hash['path'] )
    hash['installed'] = true
    setcode do
      hash
    end
  end
end
