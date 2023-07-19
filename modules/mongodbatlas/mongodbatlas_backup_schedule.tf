resource "mongodbatlas_cloud_backup_schedule" "mongodb_backup_schedule" {
  count = var.mongodbatlas_backup ? 1 : 0
  project_id   = mongodbatlas_cluster.my-cluster.project_id
  cluster_name = mongodbatlas_cluster.my-cluster.name

  # reference timezone = UTC
  reference_hour_of_day    = 02
  reference_minute_of_hour = 30

  dynamic "policy_item_hourly" {
    for_each = var.mongodbatlas_backup_policy_item_hourly_list
    content {
      frequency_interval = policy_item_hourly.value.frequency_interval
      retention_unit     = policy_item_hourly.value.retention_unit
      retention_value    = policy_item_hourly.value.retention_value
    }
  }

  dynamic "policy_item_daily" {
    for_each = var.mongodbatlas_backup_policy_item_daily_list
    content {
      frequency_interval = policy_item_daily.value.frequency_interval
      retention_unit     = policy_item_daily.value.retention_unit
      retention_value    = policy_item_daily.value.retention_value
    }
  }

  dynamic "policy_item_weekly" {
    for_each = var.mongodbatlas_backup_policy_item_weekly_list
    content {
      frequency_interval = policy_item_weekly.value.frequency_interval
      retention_unit     = policy_item_weekly.value.retention_unit
      retention_value    = policy_item_weekly.value.retention_value
    }
  }

  dynamic "policy_item_monthly" {
    for_each = var.mongodbatlas_backup_policy_item_monthly_list
    content {
      frequency_interval = policy_item_monthly.value.frequency_interval
      retention_unit     = policy_item_monthly.value.retention_unit
      retention_value    = policy_item_monthly.value.retention_value
    }
  }

  auto_export_enabled = true

  export {
    export_bucket_id = mongodbatlas_cloud_backup_snapshot_export_bucket.mongodb-snapshots-bucket[0].export_bucket_id
    frequency_type = var.mongodbatlas_backup_export_frequency_type
  }

}
