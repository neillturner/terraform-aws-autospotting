# terraform-aws-autospotting
Automatically convert your existing AutoScaling groups to significantly cheaper spot instances with minimal(often zero) configuration changes


See [https://github.com/cristim/autospotting](https://github.com/cristim/autospotting) for details.

To access from terraform:

```
module "autospotting" {
  source  = "cristim/autospotting/aws"
  version = "0.0.9"
}
```
