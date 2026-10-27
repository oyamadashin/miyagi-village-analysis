# パッケージ読み込み----
library(tidyverse)
library(readxl)
library(stringr)



# 津波割合変数をつくる----

## データ読み込み----
### 集落単位の圃場面積
farmland_total_by_village <- read_csv("data/processed/farmland_total_by_village.csv")

### 集落単位の津波被災圃場面積
tsunami_farmland_total_by_village.csv <- read_csv("data/processed/tsunami_farmland_total_by_village.csv")


## 結合前の準備----

### KEYが集落事に一意になっているかチェック　→　重複無し
farmland_total_by_village |> 
  count(KEY) |> 
  filter(n > 1)

tsunami_farmland_total_by_village.csv |> 
  count(KEY) |> 
  filter(n > 1)


### 結合できない集落はあるか　→　あるが、津波被災のない集落と思われる
farmland_total_by_village |>
  anti_join(tsunami_farmland_total_by_village.csv, by = "KEY")

### 逆方向に結合すると結合できない集落はゼロ。
tsunami_farmland_total_by_village.csv |>
  anti_join(farmland_total_by_village, by = "KEY")

## 両データを結合し、津波被災面積割合変数を作成。
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


## 結合後のチェック----
### 津波被災割合が1を超えていないかチェック→超えている

df |>
  filter(tsunami_farmland_share > 1)

### 閾値を少しだけ上げると該当集落ゼロ→1を超えたのは誤差と思われる
df |>
  filter(tsunami_farmland_share > 1.0001)

### 1を超えた集落については強制的に1に置き換える
df <- df |>
  mutate(
    tsunami_farmland_share = pmin(tsunami_farmland_share, 1)
  )

df |>
  filter(tsunami_farmland_share > 1)



# 経営規模別経営体数データを結合----

## 結合できるかどうかチェック----

### 2025年センサス読み込み
farmsize_2025 <- read_excel(
  "data/raw/census/SA1025_2025_2025_00.xlsx",
  col_types = "text"
)

### 宮城県の農業集落だけ抽出
farmsize_miyagi_2025_village <- farmsize_2025 |>
  filter(
    pref == "04",
    rcom != "000"
  )

### GISデータから津波被災集落を抽出
df_tsunami <- df |>
  filter(tsunami_farmland_share > 0)

### KEYの重複確認
df_tsunami |>
  count(KEY) |>
  filter(n > 1)

farmsize_miyagi_2025_village |>
  count(key) |>
  filter(n > 1)

### 結合
df_tsunami_2025 <- df_tsunami |>
  left_join(
    farmsize_miyagi_2025_village,
    by = c("KEY" = "key"),
    relationship = "one-to-one"
  )

# 結合が問題なくできることが確認できたので、他の時点のセンサスデータも含めて改めて結合

## 2010～2025年センサスデータをGISデータに結合----

### 各年のセンサスデータを結合用に加工する関数
prepare_census <- function(data, year) {
  data |>
    filter(
      pref == "04",
      rcom != "000"
    ) |>
    select(
      -pref, -city, -kcity, -rcom,
      -pref_name, -city_name,
      -kcity_name, -rcom_name
    ) |>
    rename_with(
      ~ paste0(.x, "_", year),
      -key
    )
}

### 2010年センサス読み込み
farmsize_2010 <- read_excel(
  "data/raw/census/SA1025_2010_2025_00.xlsx",
  col_types = "text"
)


### 2015年センサス読み込み
farmsize_2015 <- read_excel(
  "data/raw/census/SA1025_2015_2025_00.xlsx",
  col_types = "text"
)


### 2020年センサス読み込み
farmsize_2020 <- read_excel(
  "data/raw/census/SA1025_2020_2025_00.xlsx",
  col_types = "text"
)


### 2025年センサス読み込み
farmsize_2025 <- read_excel(
  "data/raw/census/SA1025_2025_2025_00.xlsx",
  col_types = "text"
)


### 各規模階層の経営体数変数名が重複しないよう年次をつける
census_2010 <- prepare_census(farmsize_miyagi_2010_village, 2010)
census_2015 <- prepare_census(farmsize_miyagi_2015_village, 2015)
census_2020 <- prepare_census(farmsize_miyagi_2020_village, 2020)
census_2025 <- prepare_census(farmsize_miyagi_2025_village, 2025)

### GISデータから津波被災集落を抽出
df_tsunami <- df |>
  filter(tsunami_farmland_share > 0)

### GISデータとセンサスデータの結合
df_tsunami_all <- df_tsunami |>
  left_join(census_2010,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(census_2015,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(census_2020,
            by = c("KEY" = "key"),
            relationship = "one-to-one") |>
  left_join(census_2025,
            by = c("KEY" = "key"),
            relationship = "one-to-one")


### 結合して行数が変わっていないことをチェック→変わっていない
nrow(df_tsunami)
nrow(df_tsunami_all)

### 各年次で結合できないKEYはないか→ない
list(
  "2010" = census_2010,
  "2015" = census_2015,
  "2020" = census_2020,
  "2025" = census_2025
) |>
  purrr::map_int(
    ~ anti_join(
      df_tsunami,
      .x,
      by = c("KEY" = "key")
    ) |>
      nrow()
  )

## 変数名を変える----


### 日本語名と英語名の対応表
name_map <- c(
  "計" = "entities_total",
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
  "150ha以上" = "size_150_plus"
)

### 4時点の変数名を一括変更
old_names <- names(df_tsunami_all)

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
names(df_tsunami_all) <- new_names

### 変更された変数名を確認
tibble(
  old_name = old_names,
  new_name = new_names
) |>
  filter(old_name != new_name)

### 変換された変数の数を年次別に確認
tibble(
  old_name = old_names,
  new_name = new_names
) |>
  filter(old_name != new_name) |>
  mutate(year = str_extract(new_name, "20(10|15|20|25)$")) |>
  count(year)

### 2025年だけ100-150ha階層がおかしいので変換がうまくできてない
### 個別に変換しておく
df_tsunami_all <- df_tsunami_all |>
  rename(
    size_100_150_2025 = `100.0～150.0_2025`
  )


## 各階層の値を数値型に変換----

### 経営体数関連の変数を抽出
entity_vars <- names(df_tsunami_all) |>
  str_subset("^(entities_total|size_)")

### 数値以外の値を確認
df_tsunami_all |>
  select(all_of(entity_vars)) |>
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "value"
  ) |>
  filter(
    !is.na(value),
    !str_detect(value, "^[0-9]+$")
  ) |>
  count(value, sort = TRUE)

### @は時点間で接続不能のデータ。→該当5つだ。分析にはあまり影響なし。
df_tsunami_all |>
  select(KEY, all_of(entity_vars)) |>
  pivot_longer(
    cols = all_of(entity_vars),
    names_to = "variable",
    values_to = "value"
  ) |>
  filter(value == "@") |>
  mutate(
    year = str_extract(variable, "20(10|15|20|25)$")
  ) |>
  distinct(KEY, year) |>
  count(year)


# 数値変換前のデータを保存
df_tsunami_all_raw <- df_tsunami_all

# 数値型に変換
df_tsunami_all <- df_tsunami_all |>
  mutate(
    across(
      all_of(entity_vars),
      ~ case_when(
        .x == "-" ~ 0,
        .x %in% c("X", "x", "...", "@") ~ NA_real_,
        TRUE ~ suppressWarnings(as.numeric(.x))
      )
    )
  )

### 数値型になっているかチェック
df_tsunami_all |>
  summarise(
    across(
      all_of(entity_vars),
      is.numeric
    )
  ) |>
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "is_numeric"
  ) |>
  count(is_numeric)


### 最終的な欠損セルの数を数える
df_tsunami_all |>
  summarise(
    across(
      all_of(entity_vars),
      ~ sum(is.na(.x))
    )
  ) |>
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    year = str_extract(variable, "20(10|15|20|25)$")
  ) |>
  group_by(year) |>
  summarise(
    total_missing = sum(n_missing),
    .groups = "drop"
  )

# ----
