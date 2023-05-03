# CircleCIによるRailsアプリのビルド・テスト・デプロイメントの自動化
## 概要
- Terraformによるインフラ構築
- Ansibleによるサーバー環境構築とアプリのデプロイ
- Serverspecによるインフラテスト
- 上記をGItHubへのpushをトリガーにCircleCIで、Terraform → Ansible → Serverspecの実装を自動でおこなう。

※ これはCloudFormationで作成したCIのTerraformバージョンです。CloudFromationバージョンは[こちら](https://github.com/mkmmr/circleci-practice/)をご参照ください。

## 目次
- [概要](#概要)
- [使用ツール](#使用ツール)
- [事前準備](#事前準備)
- [補足](#補足)
- [構成図](#構成図)
- [実装手順](#実装手順)
    - [1. Terraform 実装手順](#1-Terraform-実装手順)
        - [1-1. ローカルPCにTerraformをインストール](#1-1-ローカルPCにTerraformをインストール)
        - [1-2. TerrafromでIAM用SecretAccessKeyの発行](#1-2-TerrafromでIAM用SecretAccessKeyの発行)
        - [1-3. Terraformで遭遇したエラー](#1-3-Terraformで遭遇したエラー)
    - [2. CircleCIへのTerraform実装手順](#2-CircleCIへのTerraform実装手順)
        - [2-1. 準備](#2-1-準備)
        - [2-2. CircleCIにTerraformを実装](#2-2-CircleCIにTerraformを実装)
        - [2-3. tfstateファイルをS3バケットで管理する](#2-3-tfstateファイルをS3バケットで管理する)
        - [2-4. CircleCIで遭遇したエラー](#2-4-CircleCIで遭遇したエラー)
    - [3. 成功画面](#3-成功画面)
        - [3-1. CircleCI成功画面](#3-1-CircleCI成功画面)
        - [3-2. アプリの正常動作確認](#3-2-アプリの正常動作確認)
        - [3-3. S3に画像登録確認](#3-3-S3に画像登録確認)
- [こだわりポイント](#こだわりポイント)
- [感想](#感想)

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

## 補足
- Terraformの内容は[第１０回課題](https://github.com/mkmmr/aws-practice/tree/main/lecture10)で作成したCloudFormationと同じです。
- デプロイ用のアプリは課題用に提供されている[サンプルアプリ](https://github.com/yuta-ushijima/raisetech-live8-sample-app)を使用しています。
- 同じ内容で[CloudFormationバージョン](https://github.com/mkmmr/circleci-practice)も作成しています。
- AnsibleとServerspecはCloudFormationバージョンと同じものを使用しているため、ここでの説明は割愛しています。詳しくは[CloudFormationバージョン](https://github.com/mkmmr/circleci-practice)をご参照ください。

## 構成図
![CircleCI自動化の構成図](https://i.gyazo.com/647c51db7518f0a61a32dc30add4d19b.png)

[\[↑ 目次へ\]](#目次)

## 実装手順
### 1. Terraform 実装手順
### 1-1. ローカルPCにTerraformをインストール
- 最初は自分のPCでTerraformの動作確認し、その後CircleCIに移行した。
### 1-1-1. Terraformをインストールする。
```
$ brew install tfenv
```
- AWS CLIがインストール済みの場合、AWSとの接続設定は不要。

### 1-1-2. Terrafomeで使用するコマンド
```
# .tfファイルを保存しているディレクトリに移動する。
$ cd terraform

# 最初に実行し、Terraformの実行に必要なプラグインをインターネットから取得する。
$ terraform init

# コードの構文に問題がないことを確認する。
$ terraform validate

# コマンドを実行し、リソースを構築する。
$ terraform apply

# 構築したリソースを全て破棄する。
$ terraform destroy
```

### 1-1-3. コード記述
公式ドキュメント等を参考に記述する。

（参考）

- [Terraform 公式ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [完全初心者向けTerraform入門（AWS）](https://blog.dcs.co.jp/aws/20210401-terraformaws.html)
- [【Terraform入門】AWSのVPCとEC2を構築してみる](https://kacfg.com/terraform-vpc-ec2/)  
- [Terraform で RDS 構築して接続確認するまで - Zenn](https://zenn.dev/suganuma/articles/fe14451aeda28f)
- [TerraformでALBを構築](https://cloud5.jp/terraform-alb/)
- [TerraformでIAMユーザを作成する](https://nao-eng.com/posts/2022/11/about-terraform-iam/)
- [Automatically storing terraform AWS IAM access key output into paramstore or secrets](https://stackoverflow.com/questions/73382783/automatically-storing-terraform-aws-iam-access-key-output-into-paramstore-or-sec)
- [TerraformでAWSアカウントIDを取得する](https://www.bioerrorlog.work/entry/terraform-aws-account-id)
- [terraformでfileを相対パス記載する](https://y-ni-shi.hatenablog.com/entry/2020/06/22/235254)

[\[↑ 目次へ\]](#目次)

### 1-2. TerrafromでIAM用SecretAccessKeyの発行
TerrafromでIAMのAccessKeyを発行する場合、base64でエンコードされたPGP公開鍵か、keybaseのアカウントが必要。

（参考）[Terraformで初期パスワードとシークレットアクセスキーを持つIAMユーザを作成する - Qiita](https://qiita.com/takkii1010/items/eef57e29be6cb7061d95#2-gnupg%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%A6%E5%85%AC%E9%96%8B%E9%8D%B5%E3%82%92%E4%BD%9C%E6%88%90)

### 1-2-1. GPGのペア鍵を準備する。
- gpgをインストール
```
$ brew install gpg
```
- 既存のキーの有無を確認
```
$ gpg --list-secret-keys --keyid-format LONG

gpg: ディレクトリ'/Users/xxxx/.gnupg'が作成されました
gpg: keybox'/Users/xxxx/.gnupg/pubring.kbx'が作成されました
gpg: /Users/xxxx/.gnupg/trustdb.gpg: 信用データベースができました
```
- キーの作成 
```
$ gpg --full-generate-key

(1) RSA と RSA
4096
0 = 鍵は無期限
名前
メールアドレス
コメント（空欄）
パスフレーズ
```
- 副鍵の作成
```
$ gpg --expert --edit-key $KEYID

add key
(12) ECC (暗号化のみ)
(5) NIST P-521
0 = 鍵は無期限
q
変更を保存しますか? (y/N) y
```

- キーIDを確認する
```
$ gpg --list-secret-keys

/Users/xxxx/.gnupg/pubring.kbx
------------------------------
sec   rsa4096 2023-04-30 [SC]
      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ← キーID
uid           [  究極  ] 本名 <xxxxxxxxx@xxxx>
ssb   rsa4096 2023-04-30 [E]
ssb   nistp521 2023-04-30 [E]
```

- 副鍵の公開鍵・秘密鍵をエクスポート（ローカル環境で復号できるか確認する用）
```
$ gpg -o ＜任意のファイル名＞.public.gpg  --export キーID
$ gpg -o ＜任意のファイル名＞.private.gpg --export-secret-subkey　キーID
```

- 公開鍵をbase64でエンコード
```
$ cat ＜任意のファイル名＞.public.gpg | base64 | tr -d '\n' > ＜任意のファイル名＞.public.gpg.base64
```

### 1-2-2. TerraformにGPGの公開鍵をセットする。

- `＜任意のファイル名＞.public.gpg.base64`に出力された値をTerraformの変数に入れる。（これはGithubにはアップロードしないので、CircleCIで使用するときはCircleCIのProject環境変数にセットする。）

（terraform.tfvars）
```
pgp_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

- variables.tfに変数pgp_keyを定義しておく。

（variables.tf）
```
variable "pgp_key" {
    description = "IAMユーザーのパスワード生成で利用するpgpの公開鍵(base64形式)"
    type        = string
}
```

- .gitignoreにterraform.tfvarsを入れておく。

（.gitignore）
```
terraform.tfvars
```

- `$ terraform apply`してS3用IAMユーザーのAccessKeyとSecretAccessKeyがSecretManagerに作成されることを確認する。

- SecretAccessKeyは暗号化されているのでbase64デコードしてからgpg復号する必要がある。

```
# SecretManagerから暗号化されたSecretAccessKeyコピーして、新規作成したsecret_key_base64.txtファイルに貼り付ける。
$ vim secret_key_base64.txt

# base64 デコード
$ base64 --decode -i secret_key_base64.txt -o secret_key.txt

# gpg復号
$ gpg -o secret_key --decrypt secret_key.txt

```

（参考）

- [TerraformでIAMユーザーを作成する際にKeybaseを使わずGPG鍵をファイル(Gitリポジトリ)で管理するようにしたのでそのメモ - Qiita](https://qiita.com/_yuki_ar/items/5d41c0377252fb280581#%E4%BA%8B%E5%89%8D%E6%BA%96%E5%82%99)
- [Terraformで初期パスワードとシークレットアクセスキーを持つIAMユーザを作成する - Qiita](https://qiita.com/takkii1010/items/eef57e29be6cb7061d95)
- [GnuPGを使おう](https://okumuralab.org/~okumura/misc/220628.html)
[GitHubにGPG鍵を登録してみた - Qiita](https://qiita.com/shotakaha/items/65a708f96edbe948eb79)
- [ファイルの暗号化したい&&簡単アクセスを両立させる - Qiita](https://qiita.com/catatsuy/items/04abca99fc93a7d6d81c)
- [GPGによる公開鍵暗号と署名 | 東京大学情報基盤センター](https://lecture.ecc.u-tokyo.ac.jp/johzu/joho/Y2022/GPG/GPG/gpg_1.html)
- [GnuPG チートシート（鍵作成から失効まで）](https://text.baldanders.info/openpgp/gnupg-cheat-sheet/#revocs)
- [variables.tfとterraform.tfvarsの違いを改めて言語化してみた](https://cloudnized.com/2022/11/21/verbalize_difference_between_variables-tf_and_terraform-tfvars/)

### 1-2-3. Ansibleを実行して、S3にアクセスできるか確認する。（アクセスできれば、復号が成功している。）

- Ansibleは[CloudFormationバージョンと同じもの](https://github.com/mkmmr/circleci-practice)を使用。

- Terraformでの使用にあたってのAnsible変更点

（ansible/roles/04_MySQL/templates/database.yml.j2）
```
（変更前）
host: cfn-raisetech-rds-mysql.cqi1slx2a3cx.ap-northeast-1.rds.amazonaws.com

（変更後）
host: terraform-raisetech-rds-mysql.cqi1slx2a3cx.ap-northeast-1.rds.amazonaws.com
```

[\[↑ 目次へ\]](#目次)

### 1-3. Terraformで遭遇したエラー
### 1-3-1. IAMユーザのシークレット作成時にエラーが出る。
IAMユーザのシークレット作成時、`You can’t create this secret because a secret with this name is already scheduled for deletion.`が表示されシークレットを作成できない。

→ SecretManagerは30日間削除保留されるため、コンソール上で削除しただけでは削除できない。AWS CLIで強制削除する。

```
# 確認
$ aws secretsmanager describe-secret --secret-id terraform_s3_iam_user_secret

# 強制的に削除
$ aws secretsmanager delete-secret --secret-id terraform_s3_iam_user_secret --force-delete-without-recovery
```

（参考）[Secrets Manager で [You can’t create this secret because a secret with this name is already scheduled for deletion.]が表示された時の対応 | Classmethod](https://dev.classmethod.jp/articles/secrets-manager-error-recovery-window/)

### 1-3-2. yumアップデートができない。
SecurityGroupにegressを設定しておらず、yumアップデートができなかった。CloudFormationはインバウンドの設定だけでよかったが、Terraformはアウトバウンドの設定も必要。

[\[↑ 目次へ\]](#目次)

### 2. CircleCIへのTerraform実装手順
### 2-1. 準備
### 2-1-1. AWSでのOIDC設定
- OIDC連携用のIAMロールのカスタム信頼ポリシーに、新規CircleCIプロジェクトIDを追加する。
```
"Condition": {
  "StringLike": {
    "oidc.circleci.com/org/<組織ID>:sub": [
      "org/<組織ID>/project/<プロジェクト1ID>/user/*",
      "org/<組織ID>/project/<プロジェクト2ID>/user/*"
    ]
  }
}
```

（参考）

- [複数のキーまたは値による条件の作成 | AWSドキュメント](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference_policies_multi-value-conditions.html)
- [JSONポリシーについて簡単にまとめ](https://www.capybara-engineer.com/entry/2019/12/07/212926)

### 2-1-2. CircleCIに登録する用のgpg鍵の準備。
- gpg公開鍵は、base64エンコードしたもの（terraform.tfvarsにセットしたもの）をそのまま登録する。
- gpg秘密鍵は、改行文字`\n`を追加してから登録する。

```
# クリップボードに改行文字が追加された秘密鍵が保存される。
$ gpg -a --export-secret-subkeys キーID | cat -e | sed 's/\$/\\n/g' | pbcopy
```

（参考）[GPG Keys as Environment Variables | CircleCI Discuss](https://discuss.circleci.com/t/gpg-keys-as-environment-variables/28641)

### 2-1-3. CircleCIにProjeectの環境変数を設定する。
- GPG_KEY：gpg公開鍵（base64エンコード済み）
- GPG_SECRET_KEY：gpg秘密鍵（改行文字`\n`が追加されたもの）
- GPG_GPG_PASSPHRASE：パスフレーズ
- AWS_DEFAULT_REGION：ap-northeast-1

[\[↑ 目次へ\]](#目次)

### 2-2. CircleCIにTerraformを実装
### 2-2-1. CircleCIのTerraform部分のjob構成
- workspaceからCircleCIの環境変数をstep内に取り込む。
- terraform init
- terraform validate
- terraform apply

#### ◆ 注意点
- executorは、circleci/terraform@3.2.1 Orbsのデフォルトのものだと何故かworkspaceが読み込めなかったので、cimg/deployを使用する。
- pathでterraformのディレクトリを指定しないとterraformが起動しない。
- terraform apply時、varで公開鍵を渡してあげる。

（参考）

- [cimg/deploy | circleciデベロッパー](https://circleci.com/developer/ja/images/image/cimg/deploy)
- [CircleCI 公式のデプロイ用 Docker イメージ cimg/deploy - Qiita](https://qiita.com/suzucir/items/814cea09f08056feca69)

### 2-2-2. AWSから取得したSecretAccessKeyを復号する。
#### ◆ base64デコード
```
cat ~/secret_key_base64.txt | base64 --decode > ~/secret_key.txt
```

- ちなみに、こちらの方法だと二行目にnullが入力されていると警告が出て、その後のgpg復号ができなくなる。
```
echo $(base64 --decode ~/secret_key_base64.txt ) > ~/secret_key.txt
```

#### ◆ gpg秘密鍵での復号
- まず用意した秘密鍵をインポートする。
```
export GPG_TTY=$(tty)
source $BASH_ENV
echo -e ${GPG_SECRET_KEY} | gpg --import --batch --yes --passphrase "${GPG_PASSPHRASE}"
```

- 次に復号する。
```
export GPG_TTY=$(tty)
source $BASH_ENV
gpg --no-tty --batch --passphrase "$GPG_PASSPHRASE" --pinentry-mode loopback --output ~/secret_key --decrypt ~/secret_key.txt
```

何故か毎度$(tty)を$GPG_TTYに定義してやらないとエラーが出て動かない。

（参考）  
[GnuPG2にpublic key decryption failed: Inappropriate ioctl for deviceと怒られた時の対処法 - HatenaBlog](https://kazblog.hateblo.jp/entry/2018/05/24/210530)  

[\[↑ 目次へ\]](#目次)

### 2-3. tfstateファイルをS3バケットで管理する
チーム開発の場合、.tfstateファイルはリモート環境（AWSの場合S3）で管理するのが主流とのことで、ここでも実装してみる。

### 2-3-1. tfstateを管理するS3バケットをCloudFormationで事前に作成する。
※ Teraformで作成しないのは、その.tfstateをどのように管理すべきかが問題となるため。

- CloudFormation用ymlファイルを新規作成し、S3バケットを作成するコードを書く。
    - 「パブリックアクセス」をブロックする。
    - 「バケットのバージョニング」を有効化する。
    - 「デフォルトの暗号化」を有効化する。

（参考）

- [tfstateはS3などの共有ストレージに保存する - Terraformのきほんと応用 - Zenn](https://zenn.dev/sway/articles/terraform_staple_sharestate)
- [tfstateをローカルとS3間で移行してみた | Classmethod](https://dev.classmethod.jp/articles/tfstate-s3-local-migration-method/)
- [【Terraform】tfstateファイルをAWSのS3・DynamoDBで管理する](https://blog-benri-life.com/terraform-state-aws-s3-dynamodb-backend/)
- [TerraformのtfstateファイルをS3に配置する](https://open-groove.net/terraform/terraform-tfstate-backend-s3/)

### 2-3-2. provider.tfを編集して、S3バケットで.tfstateファイルを管理するよう設定する。
- buckendにS3を指定する。
- ここではチーム開発を想定しているので、あわせてバージョン管理についても追記する。

（terraform/provider.tf）
```
terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 4.1.0"
        }
    }

    backend "s3" {
        bucket = "terraform-raisetech-s3-for-tfstate"
        key    = "terraform.tfstate"
        region = "ap-northeast-1"
    }
}
```

（参考）[Terraformバージョンを固定する - Terraformのきほんと応用 - Zenn](https://zenn.dev/sway/articles/terraform_staple_fixversion)

### 2-3-3. CircleCIでCloudFormation作成について記述する。
- .circleci/config.ymlを編集して、Terraformより先に、CloudFormationを実行するようにする。

### 2-3-4. 無事.tfstateファイルがS3に保管された。
![.tfstateファイルがS3に保管されている画面](https://i.gyazo.com/3d1f2e0360594c76d75a8c2a41c0ae28.png)

[\[↑ 目次へ\]](#目次)

### 2-4. CircleCIで遭遇したエラー
<details>
<summary><h4>2-3-1. Terraformを実行するdirectoryのエラー</h4></summary>
working_directoryが使えない

```
Terraform initialized in an empty directory!
The directory has no Terraform configuration files.
```

→ 個々のstepでpathを指定してやるとやっと動くように。
```
（修正前）
  execute-terraform:
    steps:
      - working_directory: terraform 
      - terraform/init:
          path: .

（修正後）
  execute-terraform:
    steps:
      - terraform/init:
          path: terraform
```
</details>

<details>
<summary><h4>2-3-2. CirclrCIの変数をTerraformに入れようとすると`bad variable name`エラー</h4></summary>

`=`の前後に空白があったのがいけなかった。
```
（修正前）
export TF_VAR_gpg_key = ${GPG_KEY}

（修正後）
export TF_VAR_gpg_key=${GPG_KEY}
```
（参考）[bad variable name in sh file](https://forum.qt.io/topic/125297/bad-variable-name-in-sh-file)  
→ 結局、変数はorbsのモジュールのオプションで入れることに。
</details>

<details>
<summary><h4>2-3-3. AssumeRoleのAccessKeyがjob間で共有されない</h4></summary>

- `executor: cimg/node`なら共有されたので、`executor: terraform/default`だと共有されないらしい……？
- executorに`cimg/deploy`を使用すると、無事AccessKeyがjob間で共有されTerraformが動いた。（理屈がわからない……）

（参考）

- [cimg/deploy | circleciデベロッパー](https://circleci.com/developer/ja/images/image/cimg/deploy)
- [CircleCI 公式のデプロイ用 Docker イメージ cimg/deploy - Qiita](https://qiita.com/suzucir/items/814cea09f08056feca69)
</details>

<details>
<summary><h4>2-3-4. AWS CLIで各リソースの値を取得しようとするとエラー</h4></summary>

AWS CLIで各リソースの値を取得しようとすると、エラーが出る。
```
You must specify a region. You can also configure your region by running "aws configure"
```
CircleCIのProject環境変数にリージョンをセットする。（AWS_DEFAULT_REGION：ap-northeast-1） → 解決

</details>

<details>
<summary><h4>2-3-5. 環境によってbase64デコード方法が違う</h4></summary>

筆者のMacローカル環境で動いていたコマンドが使えない。
```
base64 --decode -i secret_key.base64 -o secret_key.txt
```

CirclrCIの実行環境とはオプションコマンドが違うらしい。
```
# CircleCI上のcimg/base環境（ubuntu）で base64 --helpした場合
$ base64 --help

Mandatory arguments to long options are mandatory for short options too.
  -d, --decode          decode data
  -i, --ignore-garbage  when decoding, ignore non-alphabet characters
  -w, --wrap=COLS       wrap encoded lines after COLS character (default 76).
                          Use 0 to disable line wrapping

      --help     display this help and exit
      --version  output version information and exit

The data are encoded as described for the base64 alphabet in RFC 4648.
When decoding, the input may contain newlines in addition to the bytes of
the formal base64 alphabet.  Use --ignore-garbage to attempt to recover
from any other non-alphabet bytes in the encoded stream.

GNU coreutils online help: <https://www.gnu.org/software/coreutils/>
Full documentation <https://www.gnu.org/software/coreutils/base64>
or available locally via: info '(coreutils) base64 invocation'
base64: extra operand ‘/home/circleci/secret_key.base64’
Try 'base64 --help' for more information.

Exited with code exit status 1
```

この方法でbase64デコードできたが、二行目にnullが入力されていると警告が出て、その後のgpg復号ができない。
```
echo $(base64 --decode ~/secret_key_base64.txt ) > ~/secret_key.txt
```

これなら問題なくbase64デコードできるように。
```
cat ~/secret_key_base64.txt | base64 --decode > ~/secret_key.txt
```
</details>

<details>
<summary><h4>2-3-6. gpg秘密鍵がCircleCIに読み込めない</h4></summary>

### （１）`gpg: no valid OpenPGP data found.`エラー
- 改行文字`\n`を追加してからCircleCIのProject環境変数として登録する。

（ターミナル）
```
$ gpg --list-secret-keys
キーIDを確認する。

$ gpg -a --export-secret-keys キーID | cat -e | sed 's/\$/\\n/g' | pbcopy
クリップボードにコピーする。
```

- importコマンドを追加する。

（.circleci/config.yml）
```
- run:
    name: import GPG key
    command: echo -e "$GPG_KEY" | gpg --import
```

### （２）`gpg: public key decryption failed: Inappropriate ioctl for device`エラー
- import前に`export GPG_TTY=$(tty)`を入れる。  

（参考）[GnuPG2にpublic key decryption failed: Inappropriate ioctl for deviceと怒られた時の対処法 - HatenaBlog](https://kazblog.hateblo.jp/entry/2018/05/24/210530)

### （３）import時にパスフレーズを求められる。
- `--import --batch --yes --passphrase "${GPG_PASSPHRASE}`でクリア。

→ これでやっとgpg秘密鍵を読み込めるように。
</details>

<details>
<summary><h4>2-3-7. gpg秘密鍵を使った復号ができない</h4></summary>

### （１）`gpg: public key decryption failed: Inappropriate ioctl for device`エラー
- importの時と同じ。最初に`export GPG_TTY=$(tty)`を入れる。  

（参考）[GnuPG2にpublic key decryption failed: Inappropriate ioctl for deviceと怒られた時の対処法 - HatenaBlog](https://kazblog.hateblo.jp/entry/2018/05/24/210530)

### （２）import時にパスフレーズを求められる。
- `--pinentry-mode loopback`で回避可能。
```
gpg --no-tty --batch --passphrase "$GPG_PASSPHRASE" --pinentry-mode loopback --output ~/secret_key --decrypt ~/secret_key.txt
```

- こちらの方法もよく紹介されているがパスフレーズを回避できなかった。GnuPG2.1.0以降、pinentry の利用が必須になって、`--passphrase-fd 0`が機能しなくなったかららしい。
```
echo ${GPG_PASSPHRASE} | gpg --passphrase-fd 0 --decrypt --batch --no-secmem-warning ~/secret_key.txt > ~/secret_key
```

（参考）

- [GnuPG | archlinux](https://wiki.archlinux.jp/index.php/GnuPG#.E7.84.A1.E4.BA.BA.E3.81.AE.E3.83.91.E3.82.B9.E3.83.95.E3.83.AC.E3.83.BC.E3.82.BA)
- [2 GPG-AGENTの呼び出し](https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html)
- [GPG Keys as Environment Variables | CircleCI Discuss](https://discuss.circleci.com/t/gpg-keys-as-environment-variables/28641)
- [错误"gpg:解密失败:无秘密密钥“时，使用黑匣子在作业圈Ci](https://cloud.tencent.com/developer/ask/sof/108428411)
- [Error "gpg: decryption failed: No secret key" when using Blackbox in job Circle Ci | stack overflow](https://stackoverflow.com/questions/58892189/error-gpg-decryption-failed-no-secret-key-when-using-blackbox-in-job-circle)
- [GnuPGで暗号化されたファイルをcronで定期的に復号する - Qiita](https://qiita.com/hiroyuki-nagata/items/c84b05bf5aea64fba1f8)
- [IBM Sterling Integrator PGP ファイル転送がファイルの暗号化解除中に次のエラーで失敗する: gpg: 公開鍵の暗号化解除に失敗しました: デバイスの不適切な ioctl](https://www.ibm.com/support/pages/ibm-sterling-integrator-pgp-file-transfers-are-failing-while-decrypting-files-error-gpg-public-key-decryption-failed-inappropriate-ioctl-device)

</details>

[\[↑ 目次へ\]](#目次)

### 3. 成功画面
### 3-1. CircleCI成功画面
![CircleCIのWorkflow成功画面](https://i.gyazo.com/e1cb1bf1c4a16fb0adb4ebe5421341e7.png)
### 3-1-1. CloudFormation成功画面
![CircleCIでのCloudFormation成功画面](https://i.gyazo.com/79e5acfee0aabee51f3fa486e0aa0211.png)
### 3-1-2. Terraform成功画面
![CircleCIでのTerraform成功画面1](https://i.gyazo.com/57773a1ebe181dddc60918869c701f2c.png)
![CircleCIでのTerraform成功画面2](https://i.gyazo.com/8e31265d63e4c22c7835fe33e85eb8e8.png)
### 3-1-3. 環境変数セット成功画面
![CircleCIでの環境変数セット成功画面](https://i.gyazo.com/e005f403e9c1f1407167289ab3e5f38f.png)
### 3-1-4. Ansible成功画面
![CircleCIでのAnsible成功画面1](https://i.gyazo.com/b3b64027e95153b1032e99548677f697.png)
![CircleCIでのAnsible成功画面2](https://i.gyazo.com/f30e8368b0dd609cec0c1704fede43ac.png)
### 3-1-5. Serverspec成功画面
![CircleCIでのServerspec成功画面](https://i.gyazo.com/4e7225425e572f8c5392bfc0ae9b10b4.png)
[\[↑ 目次へ\]](#目次)

### 3-2. アプリの正常動作確認
### New Fruit Saveした時
![アプリの正常動作確認：新規追加した時の画面](https://i.gyazo.com/9a1a7592254c125035932c5e2924fc40.png)
### 新規追加後の一覧画面
![アプリの正常動作確認：新規追加後の一覧画面](https://i.gyazo.com/10d53eddfa89beab2f5ac8f920457b26.png)
### Destroyした時
![アプリの正常動作確認：削除した時の画面](https://i.gyazo.com/7e78ad48d53b95d90a1f27c3b22a17ba.png)

[\[↑ 目次へ\]](#目次)

### 3-3. S3に画像登録確認
![S3に画像登録確認](https://i.gyazo.com/48ab7a219107d9cab4797174e80b9d7b.png)

[\[↑ 目次へ\]](#目次)

## こだわりポイント
- CircleCIからAWSへの接続には、OIDC連携してSTSを発行し、AssumeRoleで接続します。
- 画像はS3に保存されます。
- S3用のIAMユーザ、AccessKey（gpgペアキーを使用）、ALBは自動作成します。

[\[↑ 目次へ\]](#目次)

## 感想
- AssumeRoleを使う場合、一度CircleCIを止めると`$ terraform destroy`が使えないため、手動でリソースを削除しなければならず大変不便であり、誤って他のリソースを消す危険性がある。また、消し忘れるとその度にCIが止まるので作業効率が非常に悪い。RDSの削除にも時間がかかる。Terraformを使用する場合、開発時はAssumeRoleではなく、通常のIAMユーザを使用した方が良い。
- TerraformでIAMを作成しようとすると、AccessKey作成にgpgのペアキーが必要であり、実装が手間。
- 運用方法によってはCloudFormationの方が使い勝手が良いと感じた。

[\[↑ 目次へ\]](#目次)
