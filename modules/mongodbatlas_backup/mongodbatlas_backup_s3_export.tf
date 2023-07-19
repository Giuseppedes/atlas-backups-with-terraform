resource "aws_s3_bucket" "mongodb_snapshots_bucket" {
  bucket = "mongodb-snapshots"
}

resource "aws_iam_role_policy" "mongodbatlas_policy" {
  name = "mongo_setup_policy"
  role = aws_iam_role.mongodbatlas_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:GetBucketLocation",
        "Resource": "${aws_s3_bucket.mongodb_snapshots_bucket.arn}"
      },
      {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.mongodb_snapshots_bucket.arn}/*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "mongodbatlas_role" {
  name = "mongo_setup_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${mongodbatlas_cloud_provider_access_setup.setup_only.aws.atlas_aws_account_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${mongodbatlas_cloud_provider_access_setup.setup_only.aws.atlas_assumed_role_external_id}"
        }
      }
    }
  ]
}
EOF
}

resource "mongodbatlas_cloud_provider_access_setup" "setup_only" {
  project_id = var.mongodbatlas_project_id
  provider_name = "AWS"
}

resource "mongodbatlas_cloud_provider_access_authorization" "auth_role" {
  project_id = var.mongodbatlas_project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.setup_only.role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.mongodbatlas_role.arn
  }
}

resource "mongodbatlas_cloud_backup_snapshot_export_bucket" "mongodb-snapshots-bucket" {
  project_id      = var.mongodbatlas_project_id
  iam_role_id     = mongodbatlas_cloud_provider_access_setup.setup_only.role_id
  bucket_name     = aws_s3_bucket.mongodb_snapshots_bucket.id
  cloud_provider  = "AWS"

  depends_on = [
    mongodbatlas_cloud_provider_access_authorization.auth_role
  ]
}
