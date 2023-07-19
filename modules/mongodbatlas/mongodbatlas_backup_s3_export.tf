resource "aws_s3_bucket" "mongodb_snapshots_bucket" {
  count = var.mongodbatlas_backup ? 1 : 0
  bucket = "mongodb-snapshots"
}

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
