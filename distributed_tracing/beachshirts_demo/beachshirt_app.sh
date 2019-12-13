
# beachshirt distributed tracing wavefront demo
# alex h
# v1.1
# 13 dec 2019

# source :  
# https://github.com/wavefrontHQ/hackathon/tree/master/distributed-tracing/node-js-app


# COMMENT
echo "AJOUTER LE WAVEFRONT TOKEN EN PREMIER ET UNIQUE PARAMETRE"


# Set Wavefront Key
WAVEFRONT_KEY=$1
echo "WAVEFRONT_KEY = $WAVEFRONT_KEY"


# UPDATE
# ----------
# yum update -y

# PRE-REQUIS
#-----------
yum install -y git



# install NODE.JS    : https://linuxize.com/post/how-to-install-node-js-on-centos-7/
#-----------------
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
yum install -y nodejs



# install DOCKER
#-----------------
# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
# Disable SELinux
setenforce 0
sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config
# Disable memory swapping
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# Enable bridged networking and set iptables
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
# Install docker : based on "https://kubernetes.io/docs/setup/cri/"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
# to see all available version for a package : yum --showduplicates list docker-ce
yum install -y docker-ce-18.09.9-3.el7   # derniere version supportée à cette date
mkdir /etc/docker
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
systemctl daemon-reload
systemctl restart docker
systemctl enable docker


# Run JAEGER 
#----------
#docker run -d --name jaeger \
#     -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
#     -p 5775:5775/udp \
#     -p 6831:6831/udp \
#     -p 6832:6832/udp \
#     -p 5778:5778 \
#     -p 16686:16686 \
#     -p 14268:14268 \
#     -p 9411:9411 \
#     jaegertracing/all-in-one:latest


# CLONE REPO
#------------
git clone https://github.com/wavefrontHQ/hackathon.git
mv /tmp/hackathon/  /root
cd /root/hackathon/distributed-tracing/node-js-app
chmod 755 loadgen.sh


# Install Dependencies
#---------------------
npm install


# Start Service
#--------------
#node beachshirt/app.js



# Test app access : http://172.19.2.102:3000/shop/menu
# Jaeger UI :   http://172.19.2.102:16686


# how to use:
#------------
#/root/hackathon/distributed-tracing/node-js-app/loadgen.sh   : to send a request of ordering shirts every {interval} seconds. You will see some random failures which are added by us.
# Now go to Jaeger UI (http://localhost:16686), if you're using all-in-one docker image as given above and look for the traces for service "shopping" and click on Find Traces.
# Stop loadgen.




# install Wavefront Proxy
#------------------------
docker run -d --name wavefrontproxy \
  -e WAVEFRONT_URL=https://vmware.wavefront.com/api/ \
  -e WAVEFRONT_TOKEN=$WAVEFRONT_KEY \
  -e JAVA_HEAP_USAGE=512m \
  -e WAVEFRONT_PROXY_ARGS="--traceListenerPorts 30000 --histogramDistListenerPorts 2878  --traceJaegerListenerPorts 50000" \
  -p 2878:2878 \
  -p 4242:4242 \
  -p 30000:30000 \
  -p 50000:50000 \
  wavefronthq/proxy:latest


# get IP address
# --------------
my_ip=$(hostname  -I | cut -f1 -d' ')


# Stop and remove the Jaeger container
#-------------------------------------
docker stop jaeger
docker rm jaeger
docker run -d --name jaeger \
   -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
   -p 5775:5775/udp \
   -p 6831:6831/udp \
   -p 6832:6832/udp \
   -p 5778:5778 \
   -p 16686:16686 \
   -p 14268:14268 \
   -p 9411:9411 \
   -e REPORTER_TCHANNEL_HOST_PORT=$my_ip:50000 \
   -e REPORTER_TYPE=tchannel \
   jaegertracing/all-in-one:latest



# Copy script to start and stop demo
cd /root
curl -O https://raw.githubusercontent.com/ahugla/Wavefront/master/distributed_tracing/beachshirts_demo/demo_start_stop.sh



# start the app
# -------------
# node beachshirt/app.js


# how to use:
#------------
# Test app access : http://172.19.2.102:3000/shop/menu
# Voir la log de l'app : tail -f /root/hackathon/distributed-tracing/node-js-app/beachshirt.log
# Envoie de charge :   /root/hackathon/distributed-tracing/node-js-app/loadgen.sh   : to send a request of ordering shirts every {interval} seconds. You will see some random failures which are added by us.
# Go to Applications -> Traces in the Wavefront UI to visualize your traces. You can also go to Applications -> Inventory to visualize the RED metrics that are automatically derived from your tracing spans. Application name is defaulted to Jaeger
# Stop loadgen.

# Remarque : ici on ne rien dans Jaeger car il forwarde tout a Wavefront


# metrics : tracing.derived.Jaeger.  ....
