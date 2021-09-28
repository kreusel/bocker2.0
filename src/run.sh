btrfs_path='/var/bocker' && cgroups='cpu,cpuacct,memory';
container_name=${1:-"ps_$(shuf -i 42002-42254 -n 1)"}
cmd="${@:2}"
ip="10.0.0.$(echo "${container_name: -3}" | sed 's/0//g')/24"
mac="02:42:ac:11:${container_name: -4:2}:${container_name: -2}"
image_name=alpine

echo "$image_name -> $container_name ($ip [$mac]): $cmd"

btrfs subvolume snapshot "$btrfs_path/$image_name" "$btrfs_path/$container_name" > /dev/null

ip link add dev veth0_"$container_name" type veth peer name veth1_"$container_name"
ip link set dev veth0_"$container_name" up
ip link set veth0_"$container_name" master bridge0
ip netns add netns_"$container_name"
ip link set veth1_"$container_name" netns netns_"$container_name"
ip netns exec netns_"$container_name" ip link set dev lo up
ip netns exec netns_"$container_name" ip link set veth1_"$container_name" address "$mac"
ip netns exec netns_"$container_name" ip addr add "$ip" dev veth1_"$container_name"
ip netns exec netns_"$container_name" ip link set dev veth1_"$container_name" up
ip netns exec netns_"$container_name" ip route add default via 10.0.0.1

echo 'nameserver 1.1.1.1' > "$btrfs_path/$container_name"/etc/resolv.conf
echo "$cmd" > "$btrfs_path/$container_name/$container_name.cmd"

cgcreate -g "$cgroups:/$container_name"
: "${BOCKER_CPU_SHARE:=512}" && cgset -r cpu.shares="$BOCKER_CPU_SHARE" "$container_name"
: "${BOCKER_MEM_LIMIT:=512}" && cgset -r memory.limit_in_bytes="$((BOCKER_MEM_LIMIT * 1000000))" "$container_name"
cgexec -g "$cgroups:$container_name" \
	ip netns exec netns_"$container_name" \
	unshare -fmuip --mount-proc \
	chroot "$btrfs_path/$container_name" \
	/bin/sh -c "/bin/mount -t proc proc /proc && $cmd" \
	2>&1 | tee "$btrfs_path/$container_name/$container_name.log" || true

#ip link del dev veth0_"$container_name"
#ip netns del netns_"$container_name"
