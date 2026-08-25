variable "repository_name" {
  type = string
}

variable "image_tag_mutability" {
  description = "MUTABLE allows re-pushing a tag (e.g. `latest`); IMMUTABLE is the production best practice but adds friction for a demo project"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "untagged_image_expiry_days" {
  description = "Days after which untagged images are expired by the lifecycle policy"
  type        = number
  default     = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
