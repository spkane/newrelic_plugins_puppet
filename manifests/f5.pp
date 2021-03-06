# = Class: newrelic_plugins::f5
#
# This class installs/configures/manages New Relic's F5 Plugin.
# Only supported on Debian-derived and Red Hat-derived OSes.
#
# == Parameters:
#
# $license_key::     License Key for your New Relic account
#
# $install_path::    Install Path for New Relic F5 Plugin
#
# $version::         New Relic F5 Plugin Version.
#                    Currently defaults to the latest version.
#
# $agents::          Array of F5 agents that require a name, host
#                    port and snmp_community.
#
# == Requires:
#
#   puppetlabs/stdlib
#
# == Sample Usage:
#
#   class { 'newrelic_plugins::f5':
#     license_key    => 'NEW_RELIC_LICENSE_KEY',
#     install_path   => '/path/to/plugin',
#     agents         => [
#       {
#         name           => 'My F5',
#         host           => 'my-f5',
#         port           => 161,
#         snmp_community => 'public'
#       }
#     ]
#   }
#
class newrelic_plugins::f5 (
    $license_key,
    $install_path,
    $version = $newrelic_plugins::params::f5_version,
    $agents,
) inherits params {

  include stdlib

  # verify ruby is installed
  newrelic_plugins::resource::verify_ruby { 'F5 Plugin': }

  # verify attributes
  validate_absolute_path($install_path)
  validate_string($version)
  validate_array($agents)

  # verify license_key
  newrelic_plugins::resource::verify_license_key { 'F5 Plugin: Verify New Relic License Key':
    license_key => $license_key
  }

  # install f5 plugin gem
  package { 'newrelic_f5_plugin' :
    ensure   => $version,
    provider => gem
  }

  # create install directory
  exec { 'create install directory':
    command => "mkdir -p ${install_path}",
    path    => $::path,
    unless  => "test -d ${install_path}"
  }

  file { "${install_path}/config":
    ensure  => directory,
    mode    => '0644'
  }

  # newrelic_plugin.yml template
  file { "${install_path}/config/newrelic_plugin.yml":
    ensure  => file,
    content => template('newrelic_plugins/f5/newrelic_plugin.yml.erb')
  }

  # install init.d script and start service
  newrelic_plugins::resource::plugin_service { 'newrelic-f5-plugin':
    daemon_dir     => $install_path,
    plugin_name    => 'F5',
    plugin_version => $version,
    run_command    => 'f5_monitor run',
    service_name   => 'newrelic-f5-plugin'
  }

  # ordering
  Newrelic_plugins::Resource::Verify_ruby['F5 Plugin']
  ->
  Newrelic_plugins::Resource::Verify_license_key['F5 Plugin: Verify New Relic License Key']
  ->
  Package['newrelic_f5_plugin']
  ->
  Exec['create install directory']
  ->
  File["${install_path}/config"]
  ->
  File["${install_path}/config/newrelic_plugin.yml"]
  ->
  Newrelic_plugins::Resource::Plugin_service['newrelic-f5-plugin']
}

