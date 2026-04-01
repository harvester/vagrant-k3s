require 'yaml'

$root_dir = File.dirname(File.expand_path(__FILE__))
$settings = YAML.load_file(File.join($root_dir, "settings.yaml"))
$runtime_type = ""
$box = "opensuse/Leap-15.6.x86_64"

def detect_runtime
  # example: v1.24.5-rc4+rke2r1
  # groups: [v1.24.5-rc4+rke2r1, 1.24.5, rc4, rke2, r1]
  m = $settings['kubernetes_version'].match(/^v(1.3[2-5].\d+)-?(.*)\+(k3s|rke2)(r?\d)/)
  if m.nil?
    puts "Unsupported Kubernetes runtime #{$settings['kubernetes_version']}"
    exit(1)
  end

  $runtime_type = m[3]

  if $settings['net_install'] == false
    $box = "bk201z/#{$runtime_type}-#{m[1]}"
    # TODO: check box exists
  end

  File.open(File.join($root_dir, "runtime"), "w") { |f| f.write $runtime_type }
end

detect_runtime

# Pupulate a env hash to pass to provision shell env
$provision_env = {}
$settings.each { |key, value|
  $provision_env["provision_#{key}"] = value
}


Vagrant.configure("2") do |config|
  config.vm.box = $box
  # config.vm.box_version = ""
  config.vm.synced_folder ".", "/vagrant", disabled: true

  (1..$settings['cluster_size']).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.provider "libvirt" do |lv|
        lv.driver = $settings['driver']
        lv.connect_via_ssh = false
        lv.qemu_use_session = false

        if $settings['driver'] == 'kvm'
          lv.cpu_mode = 'host-passthrough'
        end

        lv.memory = 16384
        lv.cpus = 8

        if $settings['ci']
          lv.management_network_name = 'vagrant-libvirt-ci'
          lv.management_network_address = '192.168.124.0/24'
        end

        lv.storage :file, :size => '50G', :device => 'vdb'
        # lv.graphics_ip = '0.0.0.0'
      end

      node.vm.provision "shell", env: $provision_env, path: './scripts/common_prepare.sh'
      # The first node is server, others are workers
      if i == 1
        node.vm.provision "shell", env: $provision_env, path: './scripts/server_config.sh'
        node.vm.provision "shell", env: $provision_env, path: './scripts/server_install.sh'
        node.vm.provision "shell", env: $provision_env, path: './scripts/server_wait.sh'
      else
        node.vm.provision "shell", env: $provision_env, path: './scripts/agent_install.sh'
      end
    end
  end
end
