## Prerequesits

You'll need `oxide`, `omnictl`, `kubectl`, `kubectl-oidc_login`, and `talosctl` installed.

Install them with [homebrew](https://brew.sh/) and [bin](https://github.com/marcosnils/bin)
```bash
brew install siderolabs/sidero-tools
bin install oxidecomputer/oxide.rs
```

## Create disk image

We are going to create a disk image using a local [image cache](https://www.talos.dev/v1.9/talos-guides/configuration/image-cache/).
This will reduce the amount of bandwidth required when creating a cluster but is not required.

Create image cache
```bash
talosctl images default > images.txt
echo 'registry.k8s.io/pause:3.9' >> images.txt
cat images.txt | talosctl images cache-create \
    --force --image-cache-path ./cache --images=-
```
Create disk image.
Make sure to update kernel ARGs from the Omni home page
```bash
mkdir -p _out/
OMNI_ARGS="SIDEROLINK_ARGUMENTS_FROM_OMNI"
docker run --rm -t -v $PWD/cache:/cache/ \
    -v $PWD/_out:/secureboot:ro \
    -v $PWD/_out:/out \
    -v /dev:/dev \
    --privileged ghcr.io/siderolabs/imager:v1.9.4 \
      metal --image-cache /cache/ \
      --extra-kernel-arg "$OMNI_ARGS talos.dashboard.disabled=1 console=ttyS0" \
      --image-disk-size=4GB
```

Unpack the image

```bash
zstd -d _out/metal-amd64.raw.zst
```

Upload the disk image to Oxide.
This assumes you've already create a project named "omni"

```bash
oxide disk import \
    --project omni \
    --path _out/metal-amd64.raw \
    --disk talos-191 \
    --disk-block-size 512 \
    --description "Talos with Omni config" \
    --snapshot talos-191 \
    --image talos-191 \
    --image-description "Talos with Omni config" \
    --image-os talos \
    --image-version 1.9.4
```

Update instance template with image id
```bash
oxide image list --project omni
```

## Create Omni cluster

Create the machine class
```bash
omnictl apply -f ./omni/oxide.mcs.yaml
```

Create the cluster via template
```bash
omnictl cluster template sync -f ./omni/oxide.cluster.yaml
```

## Create Oxide instances

Adjust seq numbers for how many machines to create.
Adjust -P for how many calls to create in parallel.
```bash
seq 1 10 | xargs -L 1 -P 5 -- ./oxide/create-instance.sh
```

## Cleanup

To delete the oxide instances first you should delete the cluster in Omni

```bash
omnictl delete cluster oxide
```

```bash
oxide instance list --project omni \
    | jq -r '.[].name' \
    | xargs -L 1 -P 5 -- ./oxide/cleanup-instance.sh
```

Now delete the links from Omni.
Be careful if you have other machines in the Omni instance.
```bash
omnictl delete link --all
```
