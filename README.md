# CircleCIによるRailsアプリのビルド・テスト・デプロイメントの自動化
## 概要
- Terraformによるインフラ構築
- Ansibleによるサーバー環境構築とアプリのデプロイ
- Serverspecによるインフラテスト
- 上記をGItHubへのpushをトリガーにCircleCIで一気通貫におこなう

- これはCloudFormationで作成したCIのTerraformバージョンです。CloudFromationバージョンは[こちら](https://github.com/mkmmr/circleci-practice/)をご参照ください。

## 使用ツール
- CircleCI
- Terraform
- Ansible
- Serverspec

## 事前準備
- CircleCIとAWSをOIDC連携する。
- EC2用のKeyPairを発行し、CircleCIのSSHパーミッションに設定する。
- gpgで公開鍵と秘密鍵を用意し、CircleCIのProject環境変数に２つとも設定する。公開鍵はBase64エンコードしたものを登録する。（S3用IAMのアクセスキー発行時に使用）
- gpgペアキーのパスフレーズをProject環境変数に設定する。
- AWSのRegionをCircleCIのProject環境変数に設定する。

## 実装手順
- Terraform実装手順の詳細は[こちら](https://github.com/mkmmr/aws-practice/blob/main/lecture13-Terraform-ver.md)をご参照ください。
- AnsibleとServerspecの実装手順の詳細は[CloudFormationバージョン](https://github.com/mkmmr/aws-practice/blob/main/lecture13-CloudFormation-ver.md)をご参照ください。

1. Terraform 実装手順
    - ローカルPCにTerraformをインストール
    - TerrafromでIAM用SecretAccessKeyの発行
    - Terraformで遭遇したエラー
2. CircleCIへのTerraform実装手順
    - 準備
    - CircleCIにTerraformを実装
    - CircleCIで遭遇したエラー

## 構成図
![CircleCI自動化の構成図](https://github.com/mkmmr/aws-practice/blob/main/images/aws_lecture13_Terraform_12diagram.png)

## こだわりポイント
- CircleCIからAWSへの接続には、OIDC連携してSTSを発行し、AssumeRoleで接続します。
- 画像はS3に保存されます。
- S3用のIAMユーザ、AccessKey（gpgペアキーを使用）、ALBは自動作成します。
