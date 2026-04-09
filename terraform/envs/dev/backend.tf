terraform {
  backend "s3" {
    bucket       = ""
    key          = "envs/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}