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
  $confdir  =   $nagios::params::confdir,
  $service  =   $nagios::params::server_package,
  $user     =   $nagios::params::user
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

  # TODO:
  # Eraldi moodulisse, create_resources + hiera
  nagios_command { 'check_ssh_load':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/usr/lib/nagios/plugins/check_load -w $ARG1$ -c $ARG2$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/custom_commands.cfg"
  }
  # build custom path dynamically from params.pp
  nagios_command { 'check_ssh_md_raid':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/opt/nagios_plugins/check_md_raid -d $ARG1$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/custom_commands.cfg"
  }

  # collect resources and populate config dir
  Nagios_host <<||>> {
    notify  => [ Service[$service], Exec['fix-permissions'] ]
  }
  
  Nagios_service <<||>> {
    notify  => [ Service[$service], Exec['fix-permissions'] ]
  }
}