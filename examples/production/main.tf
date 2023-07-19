module "mongodbatlas" {
  source = "../../modules/mongodbatlas"

  mongodbatlas_backup                          = var.mongodbatlas_backup
  mongodbatlas_backup_export_frequency_type    = var.mongodbatlas_backup_export_frequency_type
  mongodbatlas_backup_policy_item_hourly_list  = var.mongodbatlas_backup_policy_item_hourly_list
  mongodbatlas_backup_policy_item_daily_list   = var.mongodbatlas_backup_policy_item_daily_list
  mongodbatlas_backup_policy_item_weekly_list  = var.mongodbatlas_backup_policy_item_weekly_list
  mongodbatlas_backup_policy_item_monthly_list = var.mongodbatlas_backup_policy_item_monthly_list
}
