#base install
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release vim
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y curl iptables iproute2 coreutils util-linux btrfs-progs cgroup-tools

#make filesystem for bocker
fallocate -l 10G /home/michael-docker/btrfs.img
mkfs.btrfs /home/michael-docker/btrfs.img
mkdir /var/bocker
mount /home/michael-docker/btrfs.img /var/bocker

#network setup
ip link add bridge0 type bridge
ip addr add 10.0.0.1/24 brd + dev bridge0
ip link set bridge0 up
iptables --flush
iptables -t nat -A POSTROUTING -o bridge0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1

#container setup
btrfs subvolume create /var/bocker/alpine
docker container create --name vorlage alpine
docker container export vorlage | tar xf - -C /var/bocker/alpine
docker container rm vorlage
mkdir /var/bocker/alpine/server
cat << EOF > /var/bocker/alpine/server/index.js
var http 	= require('http')
var port 	= '8080'

http.createServer(function(request, response) {
    response.writeHead(200, {'Content-Type': 'application/json'})

    response.write('{"foo": "bar"}')
    response.end()
}).listen(port)

console.log("Listening on port " + port )
EOF
