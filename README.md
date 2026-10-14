# 津波被災農業集落分析

宮城県の農業集落を単位として、農業構造の変化を検討する作業用プロジェクトです。

## 作業場所と参照資料

この README がある `miyagi-village-analysis/` をプロジェクトのルートにします。参照資料は `C:/Users/user/.codex/.chatgpt-projects/g-p-69cf12f95be08191b0e8d278d145b3f5/sources/` にある ChatGPT プロジェクトの同期資料です。編集・移動・削除せず、必要なデータは取得元から本プロジェクトの `data/` に別途配置してください。同期参照資料はこの Git リポジトリの外にあります。

## ディレクトリ

```text
data/
  raw/					元のデータ
      raw/census/            元のセンサスデータ
      raw/gis/               集落境界・農地・津波等の元GISデータ
  interim/               結合・変換途中のデータ
      interim/census/            結合・変換途中のセンサスデータ
      interim/gis/               集落境界・農地・津波等の結合・変換途中のGISデータ
  processed/             分析用データセット      
R/                       Rスクリプト（rmarkdown, quarto）
qgis/projects/           QGISプロジェクト（.qgs / .qgz）
outputs/tables/          Gitに残す小さな集計表（CSV等）
outputs/figures/         生成図・地図（Git対象外）
outputs/large/           大容量出力（Git対象外）
```

空フォルダの `.gitkeep` は構成をGitに残すための目印です。

## Gitで管理するもの

- R/Pythonコード、Quarto原稿、文書、設定、QGIS処理モデルを管理します。
- QGISプロジェクトも管理します。データ参照を相対パスで保存し、データ本体は `data/` に置きます。
- `outputs/tables/` には、公開・共有可能で再生成できる小さな集計表のみ置きます。目安は1ファイル1 MB以下です。集落別分析データや個票は `data/processed/` に置きます。
- `data/` 配下は、`.gitkeep` を除いてすべて管理対象外です。GIS形式・バイナリデータ・圧縮ファイルも追加で除外します。コードは `data/` の中に置かないでください。
- 図・地図・レンダリング結果は管理対象外です。原稿から再生成します。

`.gitignore` はファイル容量で判定できません。小さな結果を置く際はサイズを確認してください。また、既に追跡したファイルを後から自動的に除外する機能はありません。`git add -f` による除外の解除は通常行わないでください。

## 作業の進め方

1. RStudioでは `miyagi-village-analysis.Rproj` を開きます。Rスクリプトはプロジェクトルートから実行し、`data/raw/...` のような相対パスを使います。
3. QGISで座標系と農地面積の算出方法を確認します。中間データと最終GISデータは `data/gis/` に保存します。
4. 農業集落コードでセンサスとGIS集計を結合し、分析用データを `data/processed/` に保存します。コードの桁数・先頭ゼロ・境界の基準年を確認します。
