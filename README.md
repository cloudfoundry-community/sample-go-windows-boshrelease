# Sample BOSH release for Golang on Windows

This BOSH release and deployment manifest deploy a single VM with a golang application running on Windows 2016.

Another sample release is https://github.com/cloudfoundry-incubator/sample-windows-bosh-release

## Deplog

```
export BOSH_ENVIRONMENT=<bosh-alias>

# pick a stemcell
bosh2 upload-stemcell https://s3.amazonaws.com/bosh-windows-stemcells-release-candidates/light-bosh-stemcell-1093.0.0-build.1-google-aws-windows2016-go_agent.tgz
bosh2 upload-stemcell https://s3.amazonaws.com/bosh-windows-stemcells-release-candidates/light-bosh-stemcell-1093.0.0-build.1-google-kvm-windows2016-go_agent.tgz

git submodule update --init
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml
```

### Warning it can be slow

Note: it can take over 10 minutes to create Windows VMs/compile the initial package (`go_windows`), so patience is a virtue. For example, on GCP I witnessed:

```
00:48:02 | Compiling packages: go_windows/298a6ebccfb40c489560e6f65acd444ccd96fd0c (00:14:05)
01:02:07 | Compiling packages: simple-go-web-app/e1bfb211b2f9d13dc37341108c7c223d0bd3ee16 (00:01:32)
01:11:14 | Creating missing vms: webapp/0219d77d-9711-4ce2-ab16-ab05435dc5e7 (0) (00:10:45)
```

And starting the instance took 10+ mins as well. Not sure why, since the VM was already running:

```
01:21:59 | Updating instance webapp: webapp/0219d77d-9711-4ce2-ab16-ab05435dc5e7 (0) (canary) (00:13:02)
```

### Debugging

During initial deploy you might get an error about requested disk sizes:

```
00:31:10 | Compiling packages: go_windows/298a6ebccfb40c489560e6f65acd444ccd96fd0c (00:00:04)
   L Error: CPI error 'Bosh::Clouds::VMCreationFailed' with message 'VM failed to create: googleapi: Error 400: Invalid value for field 'resource.disks[0].initializeParams.diskSizeGb': '20'. Requested disk size cannot be smaller than the image size (50 GB), invalid' in 'create_vm' CPI method
```

This is caused by the default size of root disks in your cloud-config:

```
$ bosh2 int <(bosh2 cloud-config) --path /vm_types
- cloud_properties:
    machine_type: n1-standard-2
    root_disk_size_gb: 20
    root_disk_type: pd-ssd
  name: default
- cloud_properties:
    machine_type: n1-standard-2
    root_disk_size_gb: 50
    root_disk_type: pd-ssd
  name: large
```

You will need to either:

* choose a different `vm_type` that has a large enough `root_disk_size_gb`, such as `large` in the example above
* enlarge the `root_disk_size_gb` to `50` or higher on `default` and then re-deploy as above
* add a new `vm_types` entry for your Windows VMs, (say `default-windows`) then re-redeploy with a operator file to modify the `vm_type: default` to `vm_type: default-windows`

Let's do the latter as the most interesting example but least invasive to any existing deployments.

First, update the cloud-config with a new `vmtypes` entry named `default-windows`. The following will update `default-windows` if it already exists.

```
cat > cloud-config-vmtypes-default-windows.yml <<EOF
---
- type: replace
  path: /vm_types/name=default-windows?
  value:
    name: default-windows
    cloud_properties:
      machine_type: n1-standard-2
      root_disk_size_gb: 50
      root_disk_type: pd-ssd
EOF
bosh2 update-cloud-config <(bosh2 cloud-config) -o cloud-config-vmtypes-default-windows.yml
```

Finally, deploy using a provided operator patch file which uses the `vm_type: default-windows` for the instance group and compilation:

```
bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml \
  -o manifests/operator/vmtype-default-windows.yml
```

## Development

As a developer of this release, create new releases, upload and deploy them:

```
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml.yml \
    -o manifests/operators/dev.yml
```
