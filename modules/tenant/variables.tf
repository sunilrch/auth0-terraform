variable "config_dir" {
  description = "Folder containing tenant.yaml, connections.yaml, apis.yaml, roles.yaml and apps.yaml."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, staging, prod)."
  type        = string
}

variable "name_suffix" {
  description = "Suffix appended to every application name, e.g. \" (dev)\". Empty for prod."
  type        = string
  default     = ""
}
