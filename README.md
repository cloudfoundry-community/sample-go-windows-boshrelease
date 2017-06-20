# Sample BOSH release for Golang on Windows

This BOSH release and deployment manifest deploy a single VM with a golang application running on Windows 2012 R2.

## Install

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=simple-go-web-app
bosh2 upload-stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-windows2012R2-go_agent\?v=1089.0
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 deploy manifests/simple-go-web-app.yml.yml
```


## Development

As a developer of this release, create new releases, upload and deploy them:

```
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 deploy manifests/simple-go-web-app.yml.yml
```
