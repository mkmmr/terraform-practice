# ------------------------------------------------------------#
#  変数設定
# ------------------------------------------------------------#
variable "tag_name" {
    default     = "terraform-raisetech"
}

variable "region" {
    default     = "ap-northeast-1"
}

variable "vpc_cidr" {
    default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
    default     = "10.0.10.0/24"
}

variable "public_subnet_c_cidr" {
    default     = "10.0.11.0/24"
}

variable "private_subnet_a_cidr" {
    default     = "10.0.20.0/24"
}

variable "private_subnet_c_cidr" {
    default     = "10.0.21.0/24"
}

variable "mysql_master_user_pass" {
    default     = "password"
}

variable "mysql_version" {
    default     = "8.0.32"
}

variable "rds_family" {
    default     = "mysql8.0"
}

variable "pgp_key" {
    description = "IAMユーザーのパスワード生成で利用するpgpの公開鍵(base64形式)"
    type        = string
}

# variable "" {
#     default     = ""
# }
# variable "" {
#     default     = ""
# }
