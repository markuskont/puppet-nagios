# == Class: nagios::monitor
#
# Class for setting up Nagios Server
# Exported client resources are automatically loaded from puppetdb
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'nagios::monitor': }
#
class nagios::monitor (
  $confdir                =   $nagios::params::confdir,
  $service                =   $nagios::params::server_package,
  $custom_commands_file   =   $nagios::params::custom_commands_file,
  $user                   =   $nagios::params::user
  ) inherits nagios::params {
  package { $service: 
    ensure => present,
  }
  # kui exportida kliendi osa teiselt serverilt, ei teki faili kasutaja korrektselt
  exec { 'fix-permissions':
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    command     => "find ${confdir} -type f -name '*cfg' | xargs chown ${user}",
    refreshonly => true,
  }
  service { $service:
    ensure     => running,
    enable     => true,
    require    => Package[$service],
  }
  # Load monitoring0
  nagios_command { 'check_ssh_load':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/usr/lib/nagios/plugins/check_load -w $ARG1$ -c $ARG2$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  # Software raid monitoring
  nagios_command { 'check_ssh_md_raid':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/opt/nagios_plugins/check_md_raid -d $ARG1$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  # MegaCli raid monitoring
  nagios_command { 'check_ssh_megaraid_sas':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/opt/nagios_plugins/check_megaraid_sas"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  # RBL monitoring
  # move to separate pp file!
  # Start by allowing perl script dependencies to be installed
  class {'cpan':
    manage_package => false,
  }
  $modules = [ 
              "Data::Validate::Domain",
              "Data::Validate::IP",
              "Monitoring::Plugin",
              "Net::DNS",
              "Readonly"
            ]
  # Install the module for domain validation
  $modules.each |String $module| {
    cpan { "$module":
      ensure  => present,
      require => Class['::cpan'],
      force   => true,
    }    
  }
  # Distribute check script (perl)
  file { "/usr/lib/nagios/plugins/check_rbl":
    ensure => present,
    mode => '0755',
    owner => $user,
    group => root,
    source => "puppet:///modules/nagios/check_rbl",
  }
  # Finally create command for nagios
  nagios_command { 'check_rbl':
    command_line => '$USER1$/check_rbl -H $HOSTADDRESS$ -t 60 -c 1 -w 1 -s cbl.anti-spam.org.cn -s cblplus.anti-spam.org.cn -s cblless.anti-spam.org.cn -s cdl.anti-spam.org.cn -s cbl.abuseat.org -s dnsbl.cyberlogic.net -s bl.deadbeef.com -s t1.dnsbl.net.au -s spamtrap.drbl.drand.net -s spamsources.fabel.dk -s 0spam.fusionzero.com -s mail-abuse.blacklist.jippg.org -s korea.services.net -s spamguard.leadmon.net -s ix.dnsbl.manitu.net -s relays.nether.net -s no-more-funn.moensted.dk -s psbl.surriel.com -s dyna.spamrats.com -s noptr.spamrats.com -s spam.spamrats.com -s dnsbl.sorbs.net -s dul.dnsbl.sorbs.net -s old.spam.dnsbl.sorbs.net -s problems.dnsbl.sorbs.net -s safe.dnsbl.sorbs.net -s spam.dnsbl.sorbs.net -s bl.spamcannibal.org -s bl.spamcop.net -s pbl.spamhaus.org -s sbl.spamhaus.org -s xbl.spamhaus.org -s ubl.unsubscore.com -s dnsbl-1.uceprotect.net -s dnsbl-2.uceprotect.net -s dnsbl-3.uceprotect.net -s db.wpbl.inf',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  # collect resources and populate config dir
  Nagios_host <<||>> {
    notify  => [ Service[$service], Exec['fix-permissions'] ]
  }
  if $::environment == 'devel' {
    Nagios_service <<| tag == 'devel' |>> {
      notify  => [ Service[$service], Exec['fix-permissions'] ]
    }
  } else {
    Nagios_service <<| tag != 'devel' |>> {
      notify  => [ Service[$service], Exec['fix-permissions'] ]
    }
  }
}