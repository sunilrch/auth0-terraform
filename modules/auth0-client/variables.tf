variable "name" {
  description = "Application name as shown in the Auth0 dashboard."
  type        = string
}

variable "description" {
  description = "Free-text description of the application."
  type        = string
  default     = ""
}

variable "app_type" {
  description = "Auth0 application type."
  type        = string

  validation {
    condition     = contains(["spa", "regular_web", "native", "non_interactive"], var.app_type)
    error_message = "app_type must be one of: spa, regular_web, native, non_interactive (machine-to-machine)."
  }
}

variable "callbacks" {
  description = "Allowed callback URLs."
  type        = list(string)
  default     = []
}

variable "allowed_logout_urls" {
  description = "Allowed logout redirect URLs."
  type        = list(string)
  default     = []
}

variable "web_origins" {
  description = "Allowed web origins (needed for SPAs using silent auth)."
  type        = list(string)
  default     = []
}

variable "allowed_origins" {
  description = "Allowed CORS origins."
  type        = list(string)
  default     = []
}

variable "grant_types" {
  description = "Override grant types. Leave empty to use sensible defaults for the app_type."
  type        = list(string)
  default     = []
}

variable "token_lifetime" {
  description = "ID token lifetime in seconds."
  type        = number
  default     = 36000
}

variable "api_grants" {
  description = "APIs (resource servers) this client may request tokens for, mostly for M2M apps."
  type = list(object({
    audience = string
    scopes   = list(string)
  }))
  default = []
}

variable "metadata" {
  description = "Client metadata, e.g. owner team or cost centre."
  type        = map(string)
  default     = {}
}
