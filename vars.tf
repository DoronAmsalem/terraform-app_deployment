
variable "aws_region" {
  type = object({
    cidr   = string
    region = string
  })
  default = {
    cidr   = "10.0.0.0/16"
    region = "us-east-1"
  }
}

variable "public_subnet" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    AZ1 = {
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
    }

    AZ2 = {
      cidr = "10.0.6.0/24"
      az   = "us-east-1b"
    }
  }
}



variable "private_subnet" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    AZ1 = {
      cidr = "10.0.2.0/24"
      az   = "us-east-1a"
    }

    AZ2 = {
      cidr = "10.0.7.0/24"
      az   = "us-east-1b"
    }
  }
}


variable "igw_cider" {
  type    = string
  default = "0.0.0.0/0"
}


variable "nat_cider" {
  type    = string
  default = "0.0.0.0/0"
}
