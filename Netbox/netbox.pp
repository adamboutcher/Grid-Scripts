#
# Netbox installer for Puppet
# This hasn't been used or ran through a parser, YMMV.
# We target CentOS.
# 2021 - Adam Boutcher - IPPP, Durham University (UKI-SCOTGRID-DURHAM).
#

class netbox::two {
  $netbox_version = '2.11.10'
  include netbox::deps::common
  include netbox::deps::two
  class { 'netbox::deps::download':
    netbox_version => $netbox_version,
  }
  class { 'netbox::deps::config':
    netbox_version => $netbox_version,
  }
  Class['netbox::deps::common'] -> Class['netbox::deps::two']
  Class['netbox::deps::two'] -> Class['netbox::deps::download']
  Class['netbox::deps::download'] -> Class['netbox::deps::config']
}

class netbox::three {
  $netbox_version = '3.0-beta1'
  include netbox::deps::common
  include netbox::deps::three
  class { 'netbox::deps::download':
    netbox_version => $netbox_version,
  }
  class { 'netbox::deps::config':
    netbox_version => $netbox_version,
  }
  Class['netbox::deps::common'] -> Class['netbox::deps::three']
  Class['netbox::deps::three'] -> Class['netbox::deps::download']
  Class['netbox::deps::download'] -> Class['netbox::deps::config']
}

class netbox::deps::common {
  if ( $::osfamily != 'RedHat' ) {
    fail('This module is only tested on RedHat based machines')
  }
  if ! defined (File['/opt']) {
    file { '/opt':
      ensure => present,
    }
  }
  if ! defined (Package['gcc']) {
    package { 'gcc':
      ensure => installed
    }
  }
  if ! defined (Package['libxml2']) {
    package { 'libxml2':
      ensure => installed
    }
  }
  if ! defined (Package['libxml2-devel']) {
    package { 'libxml2-devel':
      ensure => installed
    }
  }
  if ! defined (Package['libffi']) {
    package { 'libffi':
      ensure => installed
    }
  }
  if ! defined (Package['libffi-devel']) {
    package { 'libffi-devel':
      ensure => installed
    }
  }
  if ! defined (Package['libpq']) {
    package { 'libfpq':
      ensure => installed
    }
  }
  if ! defined (Package['libpq-devel']) {
    package { 'libfpq-devel':
      ensure => installed
    }
  }
  if ! defined (Package['zlib']) {
    package { 'zlib':
      ensure => installed
    }
  }
  if ! defined (Package['zlib-devel']) {
    package { 'zlib-devel':
      ensure => installed
    }
  }
  if ! defined (Package['openssl']) {
    package { 'openssl':
      ensure => installed
    }
  }
  if ! defined (Package['openssl-devel']) {
    package { 'openssl-devel':
      ensure => installed
    }
  }
  if ! defined (Package['openssl-libs']) {
    package { 'openssl-libs':
      ensure => installed
    }
  }
  if ! defined (Package['wget']) {
    package { 'wget':
      ensure => installed
    }
  }
  if ! defined (Package['tar']) {
    package { 'tar':
      ensure => installed
    }
  }
}

class netbox::deps::download (
  String $netbox_version = '2.11.0'
) {
  exec { "download_netbox_$netbox_version":
    command  => "wget -q https://github.com/netbox-community/netbox/archive/refs/tags/v$netbox_version.tar.gz -O /opt/netbox.tar.gz",
    user     => 'root',
    unless   => "test -e /opt/netbox-$netbox_version",
    path     => ['/bin','/usr/bin','/usr/sbin'],
    provider => 'shell',
    notify   => Exec["untar_netbox_$netbox_version"],
  }
  exec { "untar_netbox_$netbox_version":
    command     => "tar -xzf /opt/netbox.tar.gz -C /opt",
    user        => 'root',
    unless      => "test -e /opt/netbox-$netbox_version",
    path        => ['/bin','/usr/bin','/usr/sbin'],
    provider    => 'shell',
    refreshonly => true,
    notify      => File['/opt/netbox'],
  }

}

class netbox::deps::config (
  String $netbox_version = '2.11.0'
) {
  file { '/opt/netbox':
    ensure      => link,
    target      => "/opt/netbox-$netbox_version",
    refreshonly => true,
    require     => Exec["untar_netbox_$netbox_version"],
  }
  file { "/opt/netbox-$netbox_version/gunicorn.py":
    ensure  => file,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => file('netbox/gunicorn.py'),
  }
  file { '/etc/systemd/system/netbox-rq.service':
    ensure  => file,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => file('netbox/netbox-rq.service'),
    notify  => File['netbox_systemctl_daemon_reload'],
  }
  file { '/etc/systemd/system/netbox.service':
    ensure  => file,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => file('netbox/netbox.service'),
    notify  => File['netbox_systemctl_daemon_reload'],
  }
  exec { 'netbox_systemctl_daemon_reload':
    command     => "systemctl daemon-reload",
    user        => 'root',
    path        => ['/bin','/usr/bin','/usr/sbin'],
    provider    => 'shell',
    refreshonly => true,
  }
  service { 'netbox-rq':
    ensure  => 'running',
    enable  => true,
    require => File['/etc/systemd/system/netbox-rq.service'],
  }
  service { 'netbox':
    ensure  => 'running',
    enable  => true,
    require => File['/etc/systemd/system/netbox.service'],
  }
}

class netbox::deps::two {
  if $operatingsystem == "CentOS" and $operatingsystemrelease =~ /^7.*/ {
    if ! defined (Package['python3']) {
      package { 'python3':
        ensure => installed
      }
    }
    if ! defined (Package['python3-devel']) {
      package { 'python3-devel':
        ensure => installed
      }
    }
    if ! defined (Package['python3-pip']) {
      package { 'python3-pip':
        ensure => installed
      }
    }
    if ! defined (Package['python36-lxml']) {
      package { 'python36-lxml':
        ensure => installed
      }
    }
    if ! defined (Package['python36-cffi']) {
      package { 'python36-cffi':
        ensure => installed
      }
    }
    if ! defined (Package['python36-virtualenv']) {
      package { 'python36-virtualenv':
        ensure => installed
      }
    }
  } elsif $operatingsystem == "CentOS" and $operatingsystemrelease =~ /^8.*/ {
    package { "python38-dnf-module":
      name     => "python36",
      ensure   => "3.6",
      provider => "dnfmodule",
      before   => Package["python36"],
    }
    if ! defined (Package['python36']) {
      package { 'python36':
        ensure => installed
      }
    }
    if ! defined (Package['python36-devel']) {
      package { 'python36-devel':
        ensure => installed
      }
    }
    if ! defined (Package['python3-libxml']) {
      package { 'python3-libxml':
        ensure => installed
      }
    }
    if ! defined (Package['python3-lxml']) {
      package { 'python3-lxml':
        ensure => installed
      }
    }
    if ! defined (Package['python3-cffi']) {
      package { 'python3-cffi':
        ensure => installed
      }
    }
    if ! defined (Package['python3-virtualenv']) {
      package { 'python3-virtualenv':
        ensure => installed
      }
    }
  } else {
    fail('Not supported yet supported on non-CentOS')
  }
}

class netbox::deps::three {
  if $operatingsystem == "CentOS" and $operatingsystemrelease =~ /^7.*/ {
    fail('Not supported on C7 due to requiring Python 3.8')
  } elsif $operatingsystem == "CentOS" and $operatingsystemrelease =~ /^8.*/ {
    package { "python38-dnf-module":
      name     => "python38",
      ensure   => "3.8",
      provider => "dnfmodule",
      before   => Package["python38"],
    }
    if ! defined (Package['python38']) {
      package { 'python38':
        ensure => installed
      }
    }
    if ! defined (Package['python38-devel']) {
      package { 'python38-devel':
        ensure => installed
      }
    }
    if ! defined (Package['python38-pip']) {
      package { 'python38-pip':
        ensure => installed
      }
    }
    if ! defined (Package['python38-lxml']) {
      package { 'python38-lxml':
        ensure => installed
      }
    }
    if ! defined (Package['python38-cffi']) {
      package { 'python38-cffi':
        ensure => installed
      }
    }
  } else {
    fail('Not supported yet supported on non-CentOS')
  }
}

class netbox::web::apache {
  file { '/etc/httpd/conf.d/netbox.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => file('netbox/apache.conf'),
    require => [ Service['netbox'], Package['httpd'], ],
    notify  => Service['httpd'],
  }
}

class netbox::web::nginx {
  file { '/etc/nginx/conf.d/netbox.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => file('netbox/nginx.conf'),
    require => [ Service['netbox'], Package['nginx'], ],
    notify  => Service['nginx'],
  }
}
