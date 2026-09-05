variable "repository_names" {
  description = "One ECR repository per service - each Jenkinsfile pushes to exactly one of these."
  type        = list(string)
  default = [
    "api-gateway",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "notification-service",
    "frontend",
  ]
}

variable "image_tag_mutability" {
  description = "IMMUTABLE rejects pushing a second image under a tag that already exists. Since every Jenkinsfile tags images with the git commit SHA (never reused), immutability costs nothing here and closes off a real class of mistake: a `:latest`-style tag silently pointing at different content over time."
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "ECR's built-in vulnerability scanning on every push - complements, doesn't replace, the Trivy scan already planned in the Jenkins pipeline (Trivy runs before push; this runs after, and re-scans continuously as new CVEs are published against already-pushed images)."
  type        = bool
  default     = true
}

variable "untagged_image_expiry_days" {
  description = "Untagged images (left behind when a tag is moved/overwritten, or from a failed push) are deleted after this many days. Tagged images are never auto-deleted - only genuinely orphaned layers."
  type        = number
  default     = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
