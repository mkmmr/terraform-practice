# ------------------------------------------------------------#
#  IAM
# ------------------------------------------------------------#
# create IAM
resource "aws_iam_user" "terraform_s3_iam_user" {
    name = "${var.tag_name}_railsadmin"
}

# attach IAM Policy
resource "aws_iam_user_policy_attachment" "test-attach" {
    user       = aws_iam_user.terraform_s3_iam_user.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# create Access Key
resource "aws_iam_access_key" "terraform_s3_iam_user_access_key" {
    user    = aws_iam_user.terraform_s3_iam_user.name
    pgp_key = "${var.pgp_key}"
}

# set Access Key on SecretManager
resource "aws_secretsmanager_secret" "terraform_s3_iam_user_secret" {
    name = "terraform_s3_iam_user_secret"
}

resource "aws_secretsmanager_secret_version" "terraform_s3_iam_user_secret_credentials" {
    secret_id     = aws_secretsmanager_secret.terraform_s3_iam_user_secret.id
    secret_string = jsonencode({id: aws_iam_access_key.terraform_s3_iam_user_access_key.id, key: aws_iam_access_key.terraform_s3_iam_user_access_key.encrypted_secret})
}
