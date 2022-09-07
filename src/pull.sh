image_repo=${3:-library}
image_name=${1:-alpine}
image_tag=${2:-latest}

image_location=/tmp/bocker/images/${image_repo}/${image_name}/${image_tag}
layer_location=/tmp/bocker/images/_layers
mkdir -p ${image_location}/ ${layer_location}/

repository_url=https://index.docker.io/v2
token_resp=$(curl -sSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$image_repo/$image_name:pull")
token=$(echo ${token_resp} | jq -r .token)
authorization_header="Bearer ${token}"
token_expires=$(date --date="$(echo ${token_resp} | jq -r .issued_at) + $(echo ${token_resp} | jq -r .expires_in) seconds" +%s)

manifest=$(curl -sLH "Authorization: Bearer ${token}" -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${repository_url}/${image_repo}/${image_name}/manifests/${image_tag}")
echo ${manifest} | jq . > ${image_location}/manifest.json
layers=($(echo ${manifest} | jq -r '.layers[].digest' | awk 'BEGIN { FS = ":" }; { print $2 }'))

#read -r -p "Image ${image_repo}/${image_name}:${image_tag} has $(echo $layers | wc -w) layers.\n Pull? (y|N) " answer
#case "$answer" in
#  y|Y)
mount_order=()
for layer in ${layers[*]}; do
  echo "Pulling ${layer}"

  curl -sLH "Authorization: Bearer ${token}" "${repository_url}/${image_repo}/${image_name}/blobs/sha256:${layer}" \
    --output ${layer_location}/${layer}.tar.gz
  mkdir -p ${layer_location}/${layer}
  tar -xzf ${layer_location}/${layer}.tar.gz --directory ${layer_location}/${layer}/

  #for layer in $(cat /tmp/bocker/images/library/postgres/latest/manifest.json | jq -r .layers[].digest | awk 'BEGIN { FS = ":" }; { print $2 }'
  mkdir -p /tmp/bocker/volumes/_layered/${layer}
  #mount -o bind /tmp/bocker/images/_layers/${layer} /tmp/bocker/volumes/_layered/${layer}
  mount_order+=("/tmp/bocker/volumes/_layered/${layer}/")

done
unset mount_order[-1]
echo $mount_order | head -c -2 | awk -F':' '{$NF=""; print $0}'
#  ;;
#  *)  ;;
#esac
