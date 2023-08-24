# Include some of your custom scripts here!
default:
    @just --unstable --list

install-nix:
  bash <(curl -s https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/installer-scripts/silverblue-nix-installer.sh)

install-home-manager:
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --add https://github.com/guibou/nixGL/archive/main.tar.gz nixgl
  nix-channel --update
  nix-shell '<home-manager>' -A install

install-auto-epp:
  wget https://raw.githubusercontent.com/jothi-prasath/auto-epp/master/auto-epp -O /usr/local/bin/auto-epp && chmod +x /usr/local/bin/auto-epp
  wget https://raw.githubusercontent.com/jothi-prasath/auto-epp/master/auto-epp.service -O /etc/systemd/system/auto-epp.service
  sed 's/usr/usr\/local/' /etc/systemd/system/auto-epp.service -i
  systemctl daemon-reload
  systemctl enable --now auto-epp.service