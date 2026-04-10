terraform {
  backend "s3" {
    bucket       = ""
    key          = "envs/mvp/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}
