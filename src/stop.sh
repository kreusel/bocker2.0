btrfs_path='/var/bocker' && cgroups='cpu,cpuacct,memory';
container_name=${1}

ip link del dev veth0_"$container_name"
ip netns del netns_"$container_name"

btrfs subvolume delete "$btrfs_path/$container_name" > /dev/null
cgdelete -g "$cgroups:/$container_name" &> /dev/null || true
