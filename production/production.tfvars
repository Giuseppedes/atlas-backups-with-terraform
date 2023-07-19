mongodbatlas_backup = true
mongodbatlas_backup_export_frequency_type = "weekly"
mongodbatlas_backup_policy_item_hourly = [
  {
    frequency_interval = 6
    retention_unit     = "days"
    retention_value    = 2
  }
]
mongodbatlas_backup_policy_item_daily = [
  {
    frequency_interval = 1
    retention_unit     = "days"
    retention_value    = 7
  }
]
mongodbatlas_backup_policy_item_weekly = [
  {
    frequency_interval = 1 # Monday
    retention_unit     = "weeks"
    retention_value    = 4
  },
  {
    frequency_interval = 6 # Saturday
    retention_unit     = "weeks"
    retention_value    = 4
  }
]
mongodbatlas_backup_policy_item_monthly = [
  {
    frequency_interval = 40 # Last day of the month
    retention_unit     = "months"
    retention_value    = 12
  }
]
