# Sample BOSH release for Golang on Windows

This BOSH release and deployment manifest deploy a single VM with a golang application running on Windows 2012R2.

Another sample release is https://github.com/cloudfoundry-incubator/sample-windows-bosh-release

## Deploy

```
export BOSH_ENVIRONMENT=<bosh-alias>

# pick a `windows2012R2` stemcell for your infrastructure, e.g.
# Google Compute
bosh2 upload-stemcell https://s3.us-east-2.amazonaws.com/bosh-windows-stemcells-production/light-bosh-stemcell-1200.0-google-kvm-windows2012R2-go_agent.tgz
# AWS EC2
bosh2 upload-stemcell https://s3.us-east-2.amazonaws.com/bosh-windows-stemcells-production/light-bosh-stemcell-1200.0-aws-xen-hvm-windows2012R2-go_agent.tgz
# Azure
bosh2 upload-stemcell https://s3.us-east-2.amazonaws.com/bosh-windows-stemcells-production/light-bosh-stemcell-1200.0-azure-hyperv-windows2012R2-go_agent.tgz

bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml
```

Note: You can find newer `windows2012R2` stemcells at https://bosh.io/stemcells

### Warning it can be slow

Note: it can take over 10 minutes to create Windows VMs/compile the initial package (`go_windows`), so patience is a virtue. For example, on GCP I witnessed:

```
00:48:02 | Compiling packages: go_windows/298a6ebccfb40c489560e6f65acd444ccd96fd0c (00:14:05)
01:02:07 | Compiling packages: simple-go-web-app/e1bfb211b2f9d13dc37341108c7c223d0bd3ee16 (00:01:32)
01:11:14 | Creating missing vms: webapp/0219d77d-9711-4ce2-ab16-ab05435dc5e7 (0) (00:10:45)
```


### How it should work

The deployment will run a little HTTP web app listening on port 3000.

```
$ curl 10.0.0.10:3000
Hello World
```

## Debugging deployment

Some of the debugging tips I learned when writing this BOSH release are documented at:

* https://www.starkandwayne.com/blog/debugging-a-windows-bosh-vm-and-its-firewall-rules/

### Disk size too small

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

First, update the cloud-config with a new `vmtypes` entry named `default-windows`. The following will update `default-windows` if it already exists, and set `compilation.vm_type` too.

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


- type: replace
  path: /compilation?/vm_type
  value: default-windows
EOF
bosh2 update-cloud-config <(bosh2 cloud-config) -o cloud-config-vmtypes-default-windows.yml
```

Finally, deploy using a provided operator patch file which uses the `vm_type: default-windows` for the instance group and compilation:

```
bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml \
  -o manifests/operator/vmtype-default-windows.yml
```

### Running instance logs

Debugging Windows VMs isn't simple. The simplest initial step is to ask BOSH to fetch the logs from the BOSH jobs:

```
bosh2 logs -d simple-go-web-app
tar xfz ../simple-go-web-app-*.tgz
tail -n 200 simple-go-web-app/simple-go-web-app/* simple-go-web-app/*
```

The resulting logs might look like:

```
$ tail -n 200 simple-go-web-app/simple-go-web-app/*
==> simple-go-web-app/simple-go-web-app/job-service-wrapper.err.log <==

==> simple-go-web-app/simple-go-web-app/job-service-wrapper.out.log <==
[martini] listening on :3000 (development)

==> simple-go-web-app/simple-go-web-app/job-service-wrapper.wrapper.log <==
2017-07-17 01:34:23,541 DEBUG - Starting ServiceWrapper in the CLI mode
2017-07-17 01:34:24,745 INFO  - Installing the service with id 'simple-go-web-app'
2017-07-17 01:34:24,834 DEBUG - Completed. Exit code is 0
2017-07-17 01:34:42,954 INFO  - Starting ServiceWrapper in the service mode
2017-07-17 01:34:43,203 INFO  - Starting C:\var\vcap\bosh\bin\pipe.exe  C:\var\vcap\packages\simple-go-web-app\simple-go-web-app.exe
2017-07-17 01:34:43,212 INFO  - Starting C:\var\vcap\bosh\bin\pipe.exe  C:\var\vcap\packages\simple-go-web-app\simple-go-web-app.exe
2017-07-17 01:34:43,360 INFO  - Started process 1948
2017-07-17 01:34:43,398 DEBUG - Forwarding logs of the process System.Diagnostics.Process (pipe) to winsw.SizeBasedRollingLogAppender

==> simple-go-web-app/simple-go-web-app/pipe.log <==
2017/07/17 01:34:43 pipe: configuration: &{ServiceName:simple-go-web-app LogDir:\var\vcap\sys\log/simple-go-web-app/simple-go-web-app NotifyHTTP:http://localhost:2825 SyslogHost: SyslogPort: SyslogTransport: MachineIP:10.0.0.10}
2017/07/17 01:34:43 syslog: configuration missing or incomplete
2017/07/17 01:34:43 pipe: starting
```

## Development

As a developer of this release, create new releases, upload and deploy them:

```
git submodule update --init
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml.yml \
    -o manifests/operators/dev.yml
```
