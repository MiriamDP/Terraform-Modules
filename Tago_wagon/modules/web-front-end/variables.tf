variable "app_port" {
  type        = number
  description = "Port the application listens on"
  default     = 80
}

variable "autoscaling_group_min_max" {
    type = object({
      min = number
      max = number
    })

    description = "The minimuand maximun size for autoscaling group"
  
}

variable "autoscaling_group_size" {
  type = number
  description = "Default size for autoscale group"
}

variable "environment" {
  type        = string
  description = "(Required) Environment of all resources"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Autoscale group"
  default     = "t3.micro"
}

variable "instance_tags" {
  type = map(string)
  description = "Aditional tags for the lainch template instaces"
  default = {  } //para hacerlo opcional

}

variable "launch_template_ami" {
    type = string
    description = "AMID ID to use for the laucnh template"
  
}
variable "prefix" {
  type        = string
  description = "(Required) Prefix to use for all resources in this module."
}

variable "publi_subnets_ids" {
  type = list(string)
  description = "List of public subnets ids fo the autosscale group and nlb"
}

variable "user_data_contents" {
    type = string
    description = "User data script contents for the launch template"
}

variable "vpc_id" {
  type = string
  description = "vpc id where resouyrces will be deployed"
}
