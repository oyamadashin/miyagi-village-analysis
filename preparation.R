# パッケージ読み込み----
library(tidyverse)
library(readxl)



# 津波割合変数をつくる----

## データ読み込み----
### 集落単位の圃場面積
farmland_total_by_village <- read_csv("data/processed/farmland_total_by_village.csv",
                                      show_col_types = FALSE)

### 集落単位の津波被災圃場面積
tsunami_farmland_total_by_village.csv <- read_csv("data/processed/tsunami_farmland_total_by_village.csv",
                                                  show_col_types = FALSE)




### 両データを結合し、津波被災面積割合変数を作成。
df <-  farmland_total_by_village |> 
  left_join(tsunami_farmland_total_by_village.csv, by = "KEY") |> 
  mutate(
    tsunami_total_ha = replace_na(tsunami_total_ha, 0),
    tsunami_farmland_share = if_else(
      farmland_total_ha > 0,
      tsunami_total_ha / farmland_total_ha,
      NA_real_
    )
  )

### KEYを別々のコードに分離
df <- df |>
  mutate(
    pref_code = substr(KEY, 1, 2),
    city_code = substr(KEY, 3, 5),
    kcity_code = substr(KEY, 6, 7),
    village_code = substr(KEY, 8, 10)
  )

df <- df |>
  mutate(
    area_code = paste0(city_code, "-", kcity_code)
  )



### 津波被災割合が1を超えた集落については強制的に1に置き換える
df <- df |>
  mutate(
    tsunami_farmland_share = pmin(tsunami_farmland_share, 1)
  )



# センサスデータの結合----

## 関数定義：各年のセンサスデータを結合用に加工する関数----

prepare_census <- function(data, year) {
  data |>
    filter(
      pref == "04",
      rcom != "000"
    ) |>
    select(
      -pref, -city, -kcity, -rcom,
      -pref_name, -city_name,
      -kcity_name, -rcom_name,
      -`データ年次`
    ) |>
    rename_with(
      ~ paste0(.x, "_", year),
      -key
    )
}

## 経営規模別経営体数データを結合----


### 2010年経営規模別経営体数データ読み込み
farmsize_2010 <- read_excel(
  "data/raw/census/SA1025_2010_2025_00.xlsx",
  col_types = "text"
)


### 2015年経営規模別経営体数データ読み込み
farmsize_2015 <- read_excel(
  "data/raw/census/SA1025_2015_2025_00.xlsx",
  col_types = "text"
)


### 2020年経営規模別経営体数データ読み込み
farmsize_2020 <- read_excel(
  "data/raw/census/SA1025_2020_2025_00.xlsx",
  col_types = "text"
)


### 2025年経営規模別経営体数データ読み込み
farmsize_2025 <- read_excel(
  "data/raw/census/SA1025_2025_2025_00.xlsx",
  col_types = "text"
)


### 各規模階層の経営体数変数名が重複しないよう年次をつける
farmsize_2010_value_year <- prepare_census(farmsize_2010, 2010)
farmsize_2015_value_year <- prepare_census(farmsize_2015, 2015)
farmsize_2020_value_year <- prepare_census(farmsize_2020, 2020)
farmsize_2025_value_year <- prepare_census(farmsize_2025, 2025)

### GISデータから津波被災集落を抽出
df_tsunami <- df |>
  filter(tsunami_farmland_share > 0)

### 津波被災集落GISをデータと経営規模別経営体数データの結合
df_tsunami <- df_tsunami |>
  left_join(farmsize_2010_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(farmsize_2015_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(farmsize_2020_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(farmsize_2025_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one")




## 農業用機械の所有経営体数と所有台数データを結合----

# 2010, 2015年センサス読み込み


machinery_2010 <- read_excel(
  "data/raw/census/SA1053_2010_2025_00.xlsx",
  col_types = "text"
)

machinery_2015 <- read_excel(
  "data/raw/census/SA1053_2015_2025_00.xlsx",
  col_types = "text"
)


# 各規模階層の機械関連変数名が重複しないよう年次をつける


machinery_2010_value_year <- prepare_census(machinery_2010, 2010)
machinery_2015_value_year <- prepare_census(machinery_2015, 2015)

## 結合

df_tsunami <- df_tsunami |>
  left_join(machinery_2010_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(machinery_2015_value_year,
            by = c("KEY" = "key"),
            relationship = "one-to-one") 



# 変数名を変える----


### 日本語名と英語名の対応表
name_map <- c(
  "計" = "entities_total", # ここから、規模別経営体数関連変数
  "経営耕地なし" = "size_none",
  "0.3ha未満" = "size_under_0_3",
  "0.3～0.5" = "size_0_3_0_5",
  "0.5～1.0" = "size_0_5_1",
  "1.0～1.5" = "size_1_1_5",
  "1.5～2.0" = "size_1_5_2",
  "2.0～3.0" = "size_2_3",
  "3.0～5.0" = "size_3_5",
  "5.0～10.0" = "size_5_10",
  "10.0～20.0" = "size_10_20",
  "20.0～30.0" = "size_20_30",
  "30.0～50.0" = "size_30_50",
  "50.0～100.0" = "size_50_100",
  "100～150" = "size_100_150",
  "100.0～150.0" = "size_100_150",
  "150ha以上" = "size_150_plus",
  "動力田植機_経営体数" = "transplanter_entities", #ここから、機械保有関連変数
  "動力田植機_台数" = "transplanter_units",
  "トラクター_経営体数" = "tractor_entities",
  "トラクター_台数"= "tractor_units",
  "コンバイン_経営体数" = "combine_entities",
  "コンバイン_台数"= "combine_units"
)

# 変数名対応表をCSVとして保存
name_map |>
  enframe(
    name = "original_name",
    value = "variable_name"
  ) |>
  write_excel_csv("data/processed/variable_name_map.csv")



### 4時点の変数名を一括変更
old_names <- names(df_tsunami)

new_names <- vapply(old_names, function(x) {
  
  base <- str_remove(x, "_(2010|2015|2020|2025)$")
  year <- str_extract(x, "(2010|2015|2020|2025)$")
  
  if (base %in% names(name_map) && !is.na(year)) {
    paste0(name_map[[base]], "_", year)
  } else {
    x
  }
  
}, character(1), USE.NAMES = FALSE)

### 変数名を変更
names(df_tsunami) <- new_names




## 各階層の値を数値型に変換----

### 数値型に変換したい変数を抽出
numeric_vars <- names(df_tsunami) |>
  str_subset(
    "^(entities_total|size_|transplanter_|tractor_|combine_)"
  )



# 数値型に変換
df_tsunami <- df_tsunami |>
  mutate(
    across(
      all_of(numeric_vars),
      ~ case_when(
        .x == "-" ~ 0,
        .x %in% c("X", "x", "...", "@") ~ NA_real_,
        TRUE ~ suppressWarnings(as.numeric(.x))
      )
    )
  )



# 普段の分析に使うファイルを生成---- 
## preparation.Rの内容を更新したときだけ、下記のファイルを生成し直すこと。

saveRDS(
  df_tsunami,
  "data/processed/village_analysis.rds"
)
