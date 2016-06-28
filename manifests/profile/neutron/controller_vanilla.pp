class midonet_openstack::profile::neutron::controller_vanilla {
  include ::openstack_integration::config

  rabbitmq_user { "${::midonet_openstack::params::neutron_rabbitmq_user}":
    admin    => true,
    password => "${::midonet_openstack::params::neutron_rabbitmq_password}",
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'neutron@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }
  class { '::neutron::db::mysql':
    password => "${::midonet_openstack::params::mysql_neutron_pass}",
    allowed_hosts => '%',
  }
  class { '::neutron::keystone::auth':
    password => "${::midonet_openstack::params::neutron_password}",
    region   => "${::midonet_openstack::params::region}"
  }

  class { '::neutron':
    rabbit_user           => "${::midonet_openstack::params::neutron_rabbitmq_user}",
    rabbit_password       => "${::midonet_openstack::params::neutron_rabbitmq_password}",
    rabbit_host           => $::openstack_integration::config::rabbit_host,
    rabbit_port           => $::openstack_integration::config::rabbit_port,
    rabbit_use_ssl        => $::openstack_integration::config::ssl,
    allow_overlapping_ips => true,
    core_plugin           => 'ml2',
    service_plugins       => ['router', 'metering', 'firewall'],
    debug                 => true,
    verbose               => true,
  }
  class { '::neutron::client': }
  class { '::neutron::server':
    database_connection => "mysql+pymysql://${::midonet_openstack::params::mysql_neutron_user}:${::midonet_openstack::params::mysql_neutron_pass}@127.0.0.1/neutron?charset=utf8",
    password            => "${::midonet_openstack::params::neutron_password}",
    sync_db             => true,
    api_workers         => 2,
    rpc_workers         => 2,
    auth_uri            => $::openstack_integration::config::keystone_auth_uri,
    auth_url            => $::openstack_integration::config::keystone_admin_uri,
    region_name         => "${::midonet_openstack::params::region}",
    auth_region         => "${::midonet_openstack::params::region}"
  }
  class { '::neutron::plugins::ml2':
    type_drivers         => ['vxlan'],
    tenant_network_types => ['vxlan'],
    mechanism_drivers    => ['openvswitch'],
  }
  class { '::neutron::agents::ml2::ovs':
    enable_tunneling => true,
    local_ip         => '127.0.0.1',
    tunnel_types     => ['vxlan'],
  }
  class { '::neutron::agents::metadata':
    debug            => true,
    shared_secret    => "${::midonet_openstack::params::neutron_shared_secret}",
    metadata_workers => 2,
    auth_region         => "${::midonet_openstack::params::region}",
  }
  class { '::neutron::agents::lbaas':
    debug => true,
  }
  class { '::neutron::agents::l3':
    debug => true,
  }
  class { '::neutron::agents::dhcp':
    debug => true,
  }
  class { '::neutron::agents::metering':
    debug => true,
  }
  class { '::neutron::server::notifications':
    auth_url => $::openstack_integration::config::keystone_admin_uri,
    password => $::midonet_openstack::params::nova_password,
    region_name => "${::midonet_openstack::params::region}"
  }
  class { '::neutron::services::fwaas':
    enabled => true,
    driver  => 'neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver',
  }
  include ::vswitch::ovs
}