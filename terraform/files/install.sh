BOOTSTRAP_URL=$1
ROLE=$2

mkdir /tmp/dcos
cd /tmp/dcos
curl -O http://${BOOTSTRAP_URL}/dcos_install.sh
sudo bash dcos_install.sh ${ROLE}