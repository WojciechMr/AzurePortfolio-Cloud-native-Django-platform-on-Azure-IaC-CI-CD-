variable "project" {
  type    = string
  default = "AzurePortfolio"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "backend_image" {
  type        = string
  description = "Container image for backend (including tag)"
}

variable "backend_env" {
  type        = map(string)
  description = "Environment variables for backend container app"
  default     = {}
}
