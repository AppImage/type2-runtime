# -*- mode: ruby -*-
# vi: set ft=ruby :

# we define both a Linux and a FreeBSD environment so that we can test the chroot environment on both
Vagrant.configure("2") do |config|
  config.vm.define :ubuntu do |ubuntu|
    ubuntu.vm.box = "ubuntu/jammy64"

    ubuntu.vm.provision "shell", inline: <<-SHELL
      export DPKG_FRONTEND=noninteractive
      apt-get update
      apt-get install -y wget qemu-user-static
    SHELL
  end

  config.vm.define :freebsd do |freebsd|
    freebsd.vm.box = "freebsd/FreeBSD-14.1-RELEASE"

    # on FreeBSD, vboxvfs appears to be _really_ buggy
    # therefore, we'll use good ol' rsync
    freebsd.vm.synced_folder ".", "/vagrant", type: "rsync"

    freebsd.vm.provision "shell", inline: <<-SHELL
      pkg install -y wget
    SHELL
  end
end
