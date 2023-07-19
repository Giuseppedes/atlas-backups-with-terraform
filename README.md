# atlas-backups-with-terraform
Terraform code for setting up backups on Atlas MongoDB

## Disaster recovery: How to enable automatic backups of an Atlas MongoDB cluster using Terraform and storing snapshots on AWS S3.

Assuming we have a terraform module for defining Mongo Atlas cluster,
the first step for enabling backups is to set the argument `cloud_backup` in the resource `mongodbatlas_cluster`.

```terraform
resource "mongodbatlas_cluster" "my-cluster" {
  project_id   = var.mongodbatlas_project_id
  name         = var.mongodbatlas_project_name
  provider_instance_size_name =  var.provider_instance_size_name # At least "M10"
  provider_name               = "AWS"
  
  cloud_backup                = var.mongodbatlas_backup
}
```

This will enable the cloud backup on atlas with the default policy settings (frequency and retention), we will update it later.

At this point, we need to create the S3 bucket that will be used for exporting the snapshots,
this is optional, but it's another measure in order to react to a failure on atlas, avoiding data loss.

```terraform
resource "aws_s3_bucket" "mongodb_snapshots_bucket" {
  count = var.mongodbatlas_backup ? 1 : 0
  bucket = "mongodb-snapshots"
}
```

`count` is used to optionally create the bucket depending on the value of the flag `mongodbatlas_backup`.
This is used for creating all the resources in this tutorial
and allows you to use the same template for different environment
(e.g., we are setting `mongodbatlas_backup`: `true` for production and `false` for development deployments).

Atlas needs to be allowed to write files in the bucket we've just created,
let's create a policy that grants permissions for writing objects in the bucket
and a role that will be assumed by Atlas during the export job.

```terraform
resource "aws_iam_role_policy" "mongodbatlas_policy" {
  count = var.mongodbatlas_backup ? 1 : 0
  name = "mongo_setup_policy"
  role = aws_iam_role.mongodbatlas_role[0].id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:GetBucketLocation",
        "Resource": "${aws_s3_bucket.mongodb_snapshots_bucket[0].arn}"
      },
      {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.mongodb_snapshots_bucket[0].arn}/*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "mongodbatlas_role" {
  count = var.mongodbatlas_backup ? 1 : 0
  name = "mongo_setup_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${mongodbatlas_cloud_provider_access_setup.setup_only[0].aws.atlas_aws_account_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${mongodbatlas_cloud_provider_access_setup.setup_only[0].aws.atlas_assumed_role_external_id}"
        }
      }
    }
  ]
}
EOF
}
```

This will create all the resources on AWS side, but we need to connect them with Atlas,
for this we have to use two resources: 
`mongodbatlas_cloud_provider_access_setup` and `mongodbatlas_cloud_provider_access_authorization`.

The former allows you to register AWS IAM roles in Atlas, the latter allows you to authorize them.

Note that we have used values of `mongodbatlas_cloud_provider_access_setup` for restricting the `assume_role_policy` of `aws_iam_role`.

```terraform
resource "mongodbatlas_cloud_provider_access_setup" "setup_only" {
  count = var.mongodbatlas_backup ? 1 : 0
  project_id = var.mongodbatlas_project_id
  provider_name = "AWS"
}

resource "mongodbatlas_cloud_provider_access_authorization" "auth_role" {
  count = var.mongodbatlas_backup ? 1 : 0
  project_id = var.mongodbatlas_project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.setup_only[0].role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.mongodbatlas_role[0].arn
  }
}
```

We can now use the resource `mongodbatlas_cloud_backup_snapshot_export_bucket`
to tell Atlas to use the bucket we've just created for exporting the snapshots.
Since there is no direct connection between the authorization resource and the following one,
we need to specify the dependency with `depends_on` argument.

```terraform
resource "mongodbatlas_cloud_backup_snapshot_export_bucket" "mongodb-snapshots-bucket" {
  count = var.mongodbatlas_backup ? 1 : 0
  project_id      = var.mongodbatlas_project_id
  iam_role_id     = mongodbatlas_cloud_provider_access_setup.setup_only[0].role_id
  bucket_name     = aws_s3_bucket.mongodb_snapshots_bucket[0].id
  cloud_provider  = "AWS"

  depends_on = [
    mongodbatlas_cloud_provider_access_authorization.auth_role[0]
  ]
}
```

The set-up is now complete, we only need to specify a schedule policy with auto_export enabled.

In the following code we use `dynamic` for creating a dynamic numbers of block `policy_item_XXX`
(0 to n, depending on the number of policies we specify in the variables)

```terraform
resource "mongodbatlas_cloud_backup_schedule" "mongodb_backup_schedule" {
  count = var.mongodbatlas_backup ? 1 : 0
  project_id   = mongodbatlas_cluster.my-cluster.project_id
  cluster_name = mongodbatlas_cluster.my-cluster.name

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
```

For the sake of completeness, here is the declaration of variables with sample values.

`variables.tf`

```terraform
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
```

### Production variables
Backup enabled, snapshots every 6 hours, every day,
every Monday and Saturday, every last day of the month,
weekly exports on S3.

`production.tfvars`
```terraform
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
```

### Staging variables
Backup enabled, snapshots every last day of the month, monthly exports.

`staging.tfvars`
```terraform
mongodbatlas_backup = true
mongodbatlas_backup_export_frequency_type = "monthly"
mongodbatlas_backup_policy_item_monthly = [
  {
    frequency_interval = 40 # Last day of the month
    retention_unit     = "months"
    retention_value    = 12
  }
]
```

### Development variables
Backup disabled.

`development.tfvars`
```terraform
mongodbatlas_backup = false
```
