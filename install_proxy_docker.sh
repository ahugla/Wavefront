
# INPUT


#Disable Firewall
systemctl stop firewalld
systemctl disable firewalld

#Disable SELinux
setenforce 0
sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config


# Disable memory swapping
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# Enable bridged networking
# Set iptables
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -system


# Install Docker CE
## Set up the repository
### Install required packages.
    yum install -y yum-utils device-mapper-persistent-data lvm2

### Add docker repository.
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

## Install docker ce.
yum update -y && yum install -y docker-ce-18.06.1.ce

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
systemctl enable docker



# install Wavefront Proxy container
docker run -d \
    -e WAVEFRONT_URL=https://vmware.wavefront.com/api/ \
    -e WAVEFRONT_TOKEN=73e333333-3333-3333-3333-333333ee45 \
    -e JAVA_HEAP_USAGE=512m \
    -p 2878:2878 \
    -p 4242:4242 \
    --restart always \
    wavefronthq/proxy:latest




#   https://vmware.wavefront.com/proxies/add


