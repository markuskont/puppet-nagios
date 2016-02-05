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
  # TODO:
  # Eraldi moodulisse, create_resources + hiera
  nagios_command { 'check_ssh_load':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/usr/lib/nagios/plugins/check_load -w $ARG1$ -c $ARG2$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  nagios_command { 'check_ssh_md_raid':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/opt/nagios_plugins/check_md_raid -d $ARG1$"',
    mode         => '0640',
    owner        => $user,
    target       => "${confdir}/${custom_commands_file}"
  }
  nagios_command { 'check_ssh_megaraid_sas':
    command_line => '$USER1$/check_by_ssh -H $HOSTADDRESS$ -C "/opt/nagios_plugins/check_megaraid_sas"',
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