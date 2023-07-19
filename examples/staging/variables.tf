variable "mongodbatlas_project_id" {
  type        = string
  description = "MongoDBAtlas project ID"
  default     = "YOUR-PROJECT-ID"
}

variable "mongodbatlas_project_name" {
  type        = string
  description = "MongoDBAtlas project name"
  default     = "YOUR-PROJECT-NAME"
}

variable "mongodbatlas_db_instance_size_name" {
  type        = string
  description = "MongoDB provider instance size name."
  default     = "M10"
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DB Backup Settings
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

variable "mongodbatlas_backup" {
  type        = bool
  description = "Is MongoDBAtlas Backup enabled?"
  default     = false
}

variable "mongodbatlas_backup_export_frequency_type" {
  type        = string
  description = "daily/weekly/monthly export"
  default     = "monthly"
}

variable "mongodbatlas_backup_policy_item_hourly_list" {
  type        = list(object({
    frequency_interval = number
    retention_unit = string
    retention_value = number
  }))
  description = "Backup policies for creating snapshots every X hours."
  default = []
}

variable "mongodbatlas_backup_policy_item_daily_list" {
  type        = list(object({
    frequency_interval = number
    retention_unit = string
    retention_value = number
  }))
  description = "Backup policies for creating snapshots every day. frequency_interval = 1 (1 every day)"
  default = []
}

variable "mongodbatlas_backup_policy_item_weekly_list" {
  type        = list(object({
    frequency_interval = number
    retention_unit = string
    retention_value = number
  }))
  description = "Backup policies for creating snapshots every week. 1 <= frequency_interval <= 7, where 1 represents Monday and 7 represents Sunday."
  default = []
}

variable "mongodbatlas_backup_policy_item_monthly_list" {
  type        = list(object({
    frequency_interval = number
    retention_unit = string
    retention_value = number
  }))
  description = "Backup policies for creating snapshots every month. 1 <= frequency_interval <= 28 or 40 (last day of the month)"
  default = []
}

