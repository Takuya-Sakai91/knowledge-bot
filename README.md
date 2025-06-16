# Knowledge Bot

## 概要

業務や技術学習で得た知識を即座に Slack 上で蓄積・検索できる、個人専用のナレッジベースです。「あれどうやるんだっけ？」を Slack コマンドで即座に解決し、散在する知識の一元管理を実現します。

## 機能

### `/memo`

ナレッジを登録します。カテゴリは省略可能です。

- **フォーマット**: `/memo [カテゴリ] [内容]`
- **例**: `/memo Ruby on Rails Active RecordのN+1問題はincludesで解決する`

### `/find`

登録したナレッジを内容（content）からキーワードで検索します。

- **フォーマット**: `/find [検索キーワード]`
- **例**: `/find raw_post`

### `/list`

指定したカテゴリのナレッジを一覧表示します。

- **フォーマット**: `/list [カテゴリ]`
- **例**: `/list rails`

### `/categories`

登録済みのカテゴリを一覧表示します。

- **フォーマット**: `/categories`

### 実装予定の機能

- **/random**: 登録した知識をランダムに表示し、復習を促します。

## 技術スタック

- **Backend**: Ruby on Rails 7.x (API mode)
- **Database**: PostgreSQL
- **Hosting**: Fly.io
- **External API**: Slack Web API (Slash Commands)

## セットアップ手順

### 1. ローカル環境の準備

```bash
# リポジトリをクローン
git clone https://github.com/Takuya-Sakai91/knowledge-bot.git
cd knowledge-bot

# 依存関係をインストール
bundle install

# データベースを作成
rails db:create
rails db:migrate
```

### 2. Slack App の設定

1. [Slack API](https://api.slack.com/apps) で新しいアプリを作成します。
2. **Slash Commands** を有効にし、`/memo` コマンドを作成します。
3. **Request URL** にデプロイしたアプリケーションの URL (`https://knowledge-bot-takuya-sakai.fly.dev/api/v1/slack_commands/commands`) を設定します。
4. **OAuth & Permissions** で `commands` スコープをアプリに追加します。
5. アプリをワークスペースにインストールします。
6. **Basic Information** ページで **Signing Secret** を取得し、環境変数 `SLACK_SIGNING_secret` として設定します。（この後のセキュリティ向上のステップで実装します）

### 3. Fly.io へのデプロイ

本プロジェクトは Fly.io へのデプロイを前提としています。`flyctl` がインストールされている必要があります。

```bash
# アプリケーションを初めてデプロイする場合
fly launch

# 2回目以降のデプロイ
fly deploy
```

## データモデル

### Knowledge

| カラム名     | データ型   | 説明           |
| ------------ | ---------- | -------------- |
| `id`         | `bigint`   | 主キー         |
| `category`   | `string`   | 知識のカテゴリ |
| `content`    | `text`     | 知識の内容     |
| `created_at` | `datetime` | 作成日時       |
| `updated_at` | `datetime` | 更新日時       |
