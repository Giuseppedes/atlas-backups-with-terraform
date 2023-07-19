resource "mongodbatlas_cluster" "my-cluster" {
  project_id   = var.mongodbatlas_project_id
  name         = var.mongodbatlas_cluster_name
  provider_instance_size_name =  var.mongodbatlas_db_instance_size_name # At least "M10", since backup is not available on smaller instances
  provider_name               = "AWS"

  cloud_backup                = var.mongodbatlas_backup
}

module "bf_mongodbatlas_backup" {
  count                                        = var.mongodbatlas_backup ? 1 : 0
  source                                       = "../mongodbatlas_backup"
  mongodbatlas_cluster_name                    = var.mongodbatlas_cluster_name
  mongodbatlas_project_id                      = var.mongodbatlas_project_id
  mongodbatlas_backup                          = var.mongodbatlas_backup
  mongodbatlas_backup_export_frequency_type    = var.mongodbatlas_backup_export_frequency_type
  mongodbatlas_backup_policy_item_hourly_list  = var.mongodbatlas_backup_policy_item_hourly_list
  mongodbatlas_backup_policy_item_daily_list   = var.mongodbatlas_backup_policy_item_daily_list
  mongodbatlas_backup_policy_item_weekly_list  = var.mongodbatlas_backup_policy_item_weekly_list
  mongodbatlas_backup_policy_item_monthly_list = var.mongodbatlas_backup_policy_item_monthly_list
}
