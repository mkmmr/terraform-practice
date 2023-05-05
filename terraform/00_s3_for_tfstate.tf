# ------------------------------------------------------------#
#  S3 for .tfstate file
# ------------------------------------------------------------#
# create S3
resource "aws_s3_bucket" "terraform_s3_for_tfstate" {
    bucket = "${var.tag_name}-s3-for-tfstate"
    tags = {
        Name = "${var.tag_name}-s3-for-tfstate"
    }
}

# permit public access
resource "aws_s3_bucket_public_access_block" "terraform_s3_for_tfstate_public_access_block" {
    bucket = aws_s3_bucket.terraform_s3_for_tfstate.id
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "terraform_s3_for_tfstate_versioning" {
    bucket = aws_s3_bucket.terraform_s3_for_tfstate.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_s3_for_tfstate_encryption" {
    bucket = aws_s3_bucket.terraform_s3_for_tfstate.id

    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
        }
    }
}
