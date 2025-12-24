library(dplyr)
library(tidyr)
library(forcats)

apply_filters <- function(df, manufacturer = "", model = "") {
  if (nzchar(manufacturer)) df <- df %>% filter(manufacturer == !!manufacturer)
  if (nzchar(model)) df <- df %>% filter(model == !!model)
  df
}

# Статистика по производителям
manufacturer_stats <- function(df, model = "") {
  df <- apply_filters(df, model = model)

  pop_model <- df %>%
    group_by(manufacturer, model) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(manufacturer) %>%
    slice_max(n, n = 1, with_ties = FALSE) %>%
    rename(popular_model = model) %>%
    select(manufacturer, popular_model)

  agg <- df %>%
    group_by(manufacturer) %>%
    summarise(
      avg_price = mean(price, na.rm = TRUE),
      count_sold = n(),
      .groups = "drop"
    ) %>%
    left_join(pop_model, by = "manufacturer") %>%
    arrange(desc(avg_price)) %>%
    mutate(
      rank_by_avg_price = dense_rank(desc(avg_price)),
      rank_by_count = dense_rank(desc(count_sold))
    )
  agg
}

# Средняя цена по годам
year_trend <- function(df, manufacturer = "", model = "") {
  df <- apply_filters(df, manufacturer, model)
  df %>%
    group_by(year_of_manufacture) %>%
    summarise(avg_price = mean(price, na.rm = TRUE), .groups = "drop") %>%
    arrange(year_of_manufacture)
}

# Типы топлива
fuel_ratio <- function(df, manufacturer = "", model = "") {
  df <- apply_filters(df, manufacturer, model)
  df %>%
    count(fuel_type, name = "n") %>%
    mutate(percent = 100 * n / sum(n)) %>%
    arrange(desc(percent))
}

# Пробег
mileage_distribution <- function(df, manufacturer = "", model = "") {
  df <- apply_filters(df, manufacturer, model)

  bins <- c(0, 50000, 100000, 150000, 200000, 250000, Inf)
  labels <- c("0-50k", "50-100k", "100-150k", "150-200k", "200-250k", "250k+")
  df$mileage_group <- cut(df$mileage, breaks = bins, labels = labels, include.lowest = TRUE)

  df %>%
    count(mileage_group, name = "n") %>%
    mutate(percent = round(100 * n / sum(n), 2)) %>%
    arrange(match(mileage_group, labels))
}

# Популярные модели
popular_models <- function(df, manufacturer = "", model = "") {
  df <- apply_filters(df, manufacturer, model)
  df %>%
    group_by(manufacturer, model) %>%
    summarise(count_sold = n(), .groups = "drop") %>%
    arrange(desc(count_sold))
}

# Список производителей (можно фильтровать по model)
manufacturers_list <- function(df, model = "") {
  df <- apply_filters(df, model = model)
  df %>%
    distinct(manufacturer) %>%
    arrange(manufacturer) %>%
    pull(manufacturer)
}

# Список типов топлива (можно фильтровать по model/производителю)
fuel_types_list <- function(df, manufacturer = "", model = "") {
  df <- apply_filters(df, manufacturer, model)
  df %>%
    distinct(fuel_type) %>%
    arrange(fuel_type) %>%
    pull(fuel_type)
}
