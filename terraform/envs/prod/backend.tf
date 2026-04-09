terraform {
  backend "s3" {
    bucket       = ""
    key          = "envs/prod/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}