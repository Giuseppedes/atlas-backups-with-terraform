terraform {
  required_version = "~>1.1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=2.57, <4.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~>1.10.0"
    }
  }
}
