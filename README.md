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
2. QGISで座標系と農地面積の算出方法を確認します。中間データと最終GISデータは `data/gis/` に保存します。
3. 農業集落コードでセンサスとGIS集計を結合し、分析用データを `data/processed/` に保存します。コードの桁数・先頭ゼロ・境界の基準年を確認します。

# 各データの詳細

## GIS関連

- 2010年時点集落境界データ（宮城県）
  - MA0001_2010_2010_04\rcom.shp
  - パス：C:\Users\user\Documents\r_analysis\miyagi-village-analysis\data\raw\gis\MA0001_2010_2010_04\rcom.shp
  - 入手元：https://www.maff.go.jp/j/tokei/census/shuraku_data/2010/ma/index.html（農林水産省, 地域の農業を見て・知って・活かすDB ～農林業センサスを中心とした総合データベース～）
- 2009年時点圃場位置データ（宮城県）
  - L03-b-09_5640-jgd_GML\L03-b-09_5640.shp
  - パス：C:\Users\user\Documents\r_analysis\miyagi-village-analysis\data\raw\gis\L03-b-09_5640-jgd_GML\L03-b-09_5640.shp
    - (6つのデータで宮城県全体を覆う。5640の部分は他に5641, 5740, 5741, 5840, 5841のパターンがある)
  - 入手元：https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-L03-b.html?utm_source=chatgpt.com (国土数値情報)
  - 備考：世界測地系の方をダウンロード（日本測地系の方は古いデータとの互換性のために残されているだけ）
- 津波浸水範囲（宮城県）
  - SHP\浸水範囲全体.shp
  - パス：C:\Users\user\Documents\r_analysis\miyagi-village-analysis\data\raw\gis\SHP\浸水範囲全体.shp
  - 入手元：国土地理院技術資料（2026年8月に申請して入手）
  - 備考：
    - 正式な資料名は「D1-No.589 平成23年（2011年）東日本大震災2.5万分１浸水範囲概況図（宮城県版）」。
    - 入手時の注意事項は以下の通り：
      - 地震後に撮影した空中写真及び観測された衛星画像を使用して判読したものです。浸水があった地域でも把握できていない箇所や雲等により浸水範囲が十分に判読できていない箇所があります。 

## センサス関連

- 経営耕地面積規模別経営体数
  - 2025年：SA1025_2025_2025_00.xlsx
