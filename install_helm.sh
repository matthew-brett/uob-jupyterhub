HOME_BIN=$HOME/usr/local/bin
HELM_INSTALLER=helm_installer.sh
mkdir -p $HOME_BIN
curl -L https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 -o $HELM_INSTALLER
export HELM_INSTALL_DIR=$HOME_BIN
bash $HELM_INSTALLER
echo "export PATH=$HOME_BIN:\$PATH" >> $HOME/.bashrc
