Vagrant.configure("2") do |config|
config.vm.box = "madebian12"
config.vm.box_url = "https://github.com/charliewalker-art/boxe-image-debian/releases/download/v1.0.0/package.box"

  # ── Nom de la machine ──────────────────────────────────────────────────────
  config.vm.hostname = "testtest-serverwen"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "testtest-serverwen"
    vb.memory = "1024"
  end

  config.vm.network "private_network", ip: "192.168.56.15"

# ── Provisioning Shell ─────────────────────────────────────────────────────
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
   
    apt-get install -y ansible python3-debian 

  
    # Changer le mot de passe root
    echo "root:charlie" | chpasswd

    # Création de l'utilisateur ca (si n'existe pas déjà)
    if ! id "charlie" &>/dev/null; then
      useradd -m -s /bin/bash charlie
      echo "charlie:1234" | chpasswd
    fi

    # Ajout de charlie au groupe sudo
    usermod -aG sudo charlie
  SHELL




  
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "apache/setup_apache.yml"
    ansible.verbose = "v"
  end

   
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "python/setup_agent.yml"
    ansible.verbose = "v"
  end


  
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "script/deploy_scripts.yml"
    ansible.verbose = "v"
  end

 


end