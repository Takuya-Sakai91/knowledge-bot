# Knowledge Bot

## 概要

業務や技術学習で得た知識を即座に Slack 上で蓄積・検索できる、個人専用のナレッジベースです。「あれどうやるんだっけ？」を Slack コマンドで即座に解決し、散在する知識の一元管理を実現します。

## 機能

### `/memo`

ナレッジを登録します。カテゴリは省略可能です。

- **フォーマット**: `/memo [カテゴリ] [内容]`
- **例**: `/memo Rails DBカラムの追加は rails g migration AddColumnToTable column:type`

### `/find`

登録したナレッジを内容（content）からキーワードで検索します。検索結果には、ナレッジを直接削除できるボタンが表示されます。

- **フォーマット**: `/find [検索キーワード]`
- **例**: `/find migration`

### `/list`

指定したカテゴリのナレッジを一覧表示します。検索結果には、ナレッジを直接削除できるボタンが表示されます。

- **フォーマット**: `/list [カテゴリ]`
- **例**: `/list Rails`

### `/categories`

登録済みのカテゴリを一覧表示します。

- **フォーマット**: `/categories`

## 技術スタック

- **Backend**: Ruby on Rails 7.x (API mode)
- **Database**: PostgreSQL
- **Hosting**: Fly.io
- **External API**: Slack Web API (Slash Commands, Interactivity)

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
2. **Slash Commands** を有効にし、`/memo`, `/find`, `/list`, `/categories` コマンドを作成します。
   - **Request URL**には、デプロイしたアプリケーションの URL `https://<あなたのアプリ名>.fly.dev/api/v1/slack_commands` を設定します。
3. **Interactivity & Shortcuts** を有効にします。
   - **Request URL**には `https://<あなたのアプリ名>.fly.dev/api/v1/slack_interactions` を設定します。
4. **OAuth & Permissions** で以下のスコープをアプリに追加します。
   - `commands`
5. アプリをワークスペースにインストールします。
6. **Basic Information** ページで **Signing Secret** を取得し、`SLACK_SIGNING_SECRET` として Fly.io の環境変数に設定します。
7. **OAuth & Permissions** ページで **Bot User OAuth Token** (`xoxb-`で始まる)を取得し、`SLACK_API_TOKEN` として Fly.io の環境変数に設定します。

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
