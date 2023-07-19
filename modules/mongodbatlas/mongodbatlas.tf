resource "mongodbatlas_cluster" "my-cluster" {
  project_id   = var.mongodbatlas_project_id
  name         = var.mongodbatlas_project_name
  provider_instance_size_name =  var.mongodbatlas_db_instance_size_name # At least "M10", since backup is not available on smaller instances
  provider_name               = "AWS"

  cloud_backup                = var.mongodbatlas_backup
}
