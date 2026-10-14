# 七ヶ浜研究：農業集落単位 EDA・GIS分析

宮城県の農業集落を単位として、津波被災農地割合と農業構造の変化、復興交付金 C-1・C-4 事業との関係を検討する作業用プロジェクトです。

## 作業場所と参照資料

この README がある `miyagi-village-analysis/` をプロジェクトのルートにします。参照資料は `C:/Users/user/.codex/.chatgpt-projects/g-p-69cf12f95be08191b0e8d278d145b3f5/sources/` にある ChatGPT プロジェクトの同期資料です。編集・移動・削除せず、必要なデータは取得元から本プロジェクトの `data/` に別途配置してください。同期参照資料はこの Git リポジトリの外にあります。

## ディレクトリ

```text
config/                  共有設定・相対パス定義（秘密情報は置かない）
data/
  raw/census/            元のセンサスデータ
  raw/gis/               集落境界・農地・津波等の元GISデータ
  interim/               結合・変換途中の表データ
  processed/             分析用データセット
  gis/interim/           GIS処理途中のデータ
  gis/processed/         GIS処理済みデータ
R/                       共通R関数
scripts/eda/             EDA用Rスクリプト
scripts/gis/             GIS処理用R・Pythonスクリプト
qgis/projects/           QGISプロジェクト（.qgs / .qgz）
qgis/models/             QGIS処理モデル（.model3）
reports/                 Quarto原稿（.qmd）
docs/                    分析計画・変数定義・作業記録
outputs/tables/          Gitに残す小さな集計表（CSV等）
outputs/figures/         生成図・地図（Git対象外）
outputs/large/           大容量出力（Git対象外）
```

空フォルダの `.gitkeep` は構成をGitに残すための目印です。

## Gitで管理するもの

- R/Pythonコード、Quarto原稿、文書、設定、QGIS処理モデルを管理します。
- QGISプロジェクトも管理します。データ参照を相対パスで保存し、データ本体は `data/` に置きます。認証情報や個人の絶対パスを含めないでください。
- `outputs/tables/` には、公開・共有可能で再生成できる小さな集計表のみ置きます。目安は1ファイル1 MB以下です。集落別分析データや個票は `data/processed/` に置きます。
- `data/` 配下は、`.gitkeep` を除いてすべて管理対象外です。GIS形式・バイナリデータ・圧縮ファイルも追加で除外します。コードは `data/` の中に置かないでください。
- 図・地図・レンダリング結果は管理対象外です。原稿から再生成します。

`.gitignore` はファイル容量で判定できません。小さな結果を置く際はサイズを確認してください。また、既に追跡したファイルを後から自動的に除外する機能はありません。`git add -f` による除外の解除は通常行わないでください。

## 作業の始め方

1. RStudioでは `miyagi-village-analysis.Rproj` を開きます。Rスクリプトはプロジェクトルートから実行し、`data/raw/...` のような相対パスを使います。
2. 元データを対応する `data/raw/` に配置し、`docs/data_inventory.csv` に出典・時点・座標系・単位を記録します。元データは上書きせず、処理結果を別フォルダに保存します。
3. QGISで座標系と農地面積の算出方法を確認し、処理を `scripts/gis/` または `qgis/models/` に保存します。中間データと最終GISデータは `data/gis/` に保存します。
4. 農業集落コードでセンサスとGIS集計を結合し、分析用データを `data/processed/` に保存します。コードの桁数・先頭ゼロ・境界の基準年を確認します。
5. EDAコードを `scripts/eda/`、解釈と原稿を `reports/` に置きます。小集落の除外による感度分析は、閾値・除外数・主分析との差を記録します。
6. `quarto render reports/index.qmd` で雛形をHTMLに出力できます（Quartoのインストールが必要です）。

この雛形ではパッケージのインストールや分析実行は行っていません。使用パッケージが決まった段階で `renv` 等を導入し、環境情報を記録してください。

## 保存前の確認

```sh
git status --short
git diff --stat
git check-ignore data/raw/gis/example.gpkg
git add README.md .gitignore R scripts qgis reports docs config outputs/tables
git diff --cached --stat
```

Gitはコードの履歴管理用です。除外データは別途バックアップし、取得元・取得日・再作成手順を記録してください。初期コミットとリモートへの公開はまだ行っていません。
