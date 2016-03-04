require 'open3'

Facter.add("email_server") do
  hash = {}
  cmd = "which postfix sendmail"

  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    while line = stdout.gets
      hash['path'] = line.strip
    end
  end
  if ( hash['path'] )
    hash['installed'] = true
    setcode do 
      hash
    end
  end
end