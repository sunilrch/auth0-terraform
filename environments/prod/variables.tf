variable "environment" {
  description = "Environment name (dev, qa, staging, prod)."
  type        = string
}

variable "name_suffix" {
  description = "Optional suffix appended to every app name, e.g. \" (dev)\". Empty for prod."
  type        = string
  default     = ""
}
