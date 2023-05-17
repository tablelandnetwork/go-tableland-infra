# go-tableland-infra

A collection of Terraform files to setup the new [go-tableland](https://github.com/tablelandnetwork/go-tableland) infrastructure on GCP.

_Note: this repository is work in progress_

A high level setup is desribed in the following diagram:

<img src="https://user-images.githubusercontent.com/5305984/236659370-ac2c9ea9-fe69-4bb3-aaf4-19f36596657d.png" width="800" height="600">


### usage

##### Initial setup (one time)

```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v1 \
TF_VAR_deployment=false \
terraform apply
```

##### On deployment bring up a new stack
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

##### Traffic switch

###### Switch traffic to the new stack
```sh
TF_VAR_active_stack=green \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

###### Update the Old stack
```sh
TF_VAR_active_stack=green \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

###### Switch traffic back to (updated) old stack
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

##### Clean up deployment stack
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=false \
terraform apply
```

### TODOs

- [ ] Ensure proper roles are assigned in IAM
- [ ] Attach proper labels and tags on resource
- [ ] Make resource names follow naming conventions
- [ ] Test firewall rules