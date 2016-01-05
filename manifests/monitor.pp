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
  # collect resources and populate config dir
  Nagios_host <<||>> {
    notify  => [ Service[$service], Exec['fix-permissions'] ]
  }
  
  Nagios_service <<||>> {
    notify  => [ Service[$service], Exec['fix-permissions'] ]
  }
}