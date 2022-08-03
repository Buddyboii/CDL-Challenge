variable "cidr_block" {
  type        = string
  default     = "192.168.0.0/16"
  description = "description"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}


variable "instance_class" {
  type = string
  default = "db.t3.micro"
}

variable "engine" {
  type        = string
  default     = "postgres"
  description = "description"
}

variable "engine_version" {
  type        = string
  default     = "14.2"
  description = "description"
}

variable "db_username" {
  type        = string
  default     = "terra"
  description = "description"

}

variable "db_password" {
  type        = string
  default     = "y64B35*Km$4$jWe&PbX&"
  description = "description"
}


variable "db_identifier" {
  type        = string
  default     = "terra-db"
  description = "description"
}

variable "db_replica_identifier" {
  type        = string
  default     = "terra-db-replica"
  description = "description"
}



