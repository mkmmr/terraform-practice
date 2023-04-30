# ------------------------------------------------------------#
#  S3
# ------------------------------------------------------------#
# create S3
resource "aws_s3_bucket" "terraform_s3" {
    bucket = "${var.tag_name}"
    tags = {
        Name = "${var.tag_name}-s3"
    }
}

# permit public access
resource "aws_s3_bucket_public_access_block" "terraform_s3_public_access_block" {
    bucket = aws_s3_bucket.terraform_s3.id
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

# create Bucket Policy
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
    bucket = aws_s3_bucket.terraform_s3.id
    policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "allow_access_from_another_account" {
    statement {
        sid = "Statement1"
        principals {
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.terraform_s3_iam_user.name}"]
        }
        actions = [
            "S3:*",
        ]
        resources = [
            aws_s3_bucket.terraform_s3.arn,
            "${aws_s3_bucket.terraform_s3.arn}/*",
        ]
    }
}
