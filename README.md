# Sample BOSH release for Golang on Windows

This BOSH release and deployment manifest deploy a single VM with a golang application running on Windows 2012 R2.

Another sample release is https://github.com/cloudfoundry-incubator/sample-windows-bosh-release

## Install

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


## Development

As a developer of this release, create new releases, upload and deploy them:

```
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 -d simple-go-web-app deploy manifests/simple-go-web-app.yml.yml
```
