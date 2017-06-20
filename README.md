# BOSH release for sample-go-windows

This BOSH release and deployment manifest deploy a cluster of sample-go-windows.

## Install

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=sample-go-windows
bosh2 deploy manifests/sample-go-windows.yml --vars-store tmp/creds.yml
```

If your BOSH has Credhub, then you can omit `--vars-store` flag. It is used to generate any passwords/credentials/certificates required by `manifests/sample-go-windows.yml`.


## Development

As a developer of this release, create new releases, upload and deploy them:

```
bosh2 create-release --force && \
  bosh2 -n upload-release && \
  bosh2 deploy manifests/sample-go-windows.yml --vars-store tmp/creds.yml
```

If your BOSH has Credhub, then you can omit `--vars-store` flag. It is used to generate any passwords/credentials/certificates required by `manifests/sample-go-windows.yml`.
