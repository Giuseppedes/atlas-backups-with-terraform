mongodbatlas_backup = true
mongodbatlas_backup_export_frequency_type = "monthly"
mongodbatlas_backup_policy_item_monthly_list = [
  {
    frequency_interval = 40 # Last day of the month
    retention_unit     = "months"
    retention_value    = 12
  }
]
