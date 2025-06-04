variable "parameter_name" {
  description = "The name of the SSM parameter"
  type        = string
}

variable "parameter_value" {
  description = "The value of the SSM parameter"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the parameter"
  type        = map(string)
  default     = {}
} 