# analytics.R
library(dplyr)
library(tidyr)
library(forcats)

# 1️⃣ Средняя цена, количество и популярная модель по производителям
manufacturer_stats <- function(df) {
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
    mutate(rank_by_avg_price = dense_rank(desc(avg_price)),
           rank_by_count = dense_rank(desc(count_sold)))
  agg
}

# 2️⃣ Средняя цена по годам выпуска (фильтр по производителю)
year_trend <- function(df, manufacturer = NULL) {
  if (!is.null(manufacturer) && nzchar(manufacturer)) {
    df <- df %>% filter(manufacturer == !!manufacturer)
  }
  df %>%
    group_by(year_of_manufacture) %>%
    summarise(avg_price = mean(price, na.rm = TRUE), .groups = "drop") %>%
    arrange(year_of_manufacture)
}

# 3️⃣ Соотношение по типу топлива (фильтр по производителю)
fuel_ratio <- function(df, manufacturer = NULL) {
  if (!is.null(manufacturer) && nzchar(manufacturer)) {
    df <- df %>% filter(manufacturer == !!manufacturer)
  }
  df %>%
    count(fuel_type, name = "n") %>%
    mutate(percent = 100 * n / sum(n)) %>%
    arrange(desc(percent))
}

# 4️⃣ Распределение по пробегу
mileage_distribution <- function(df) {
  bins <- c(0, 50000, 100000, 150000, 200000, 250000, Inf)
  labels <- c("0-50k", "50-100k", "100-150k", "150-200k", "200-250k", "250k+")
  df$mileage_group <- cut(df$mileage, breaks = bins, labels = labels, include.lowest = TRUE)
  df %>%
    count(mileage_group, name = "n") %>%
    mutate(percent = round(100 * n / sum(n), 2)) %>%
    arrange(match(mileage_group, labels))
}

# 5️⃣ Прогноз цены (по производителю, году, объёму двигателя, пробегу, возрасту и типу топлива)
predict_price <- function(df, manufacturer, year_of_manufacture, engine_size, mileage, car_age, fuel_type) {
  df_model <- df %>%
    mutate(
      manufacturer = fct_lump(factor(manufacturer), n = 15, other_level = "Other"),
      fuel_type = fct_lump(factor(fuel_type), n = 10, other_level = "Other")
    )
  
  fit <- lm(
    price ~ year_of_manufacture + engine_size + mileage + car_age + manufacturer + fuel_type,
    data = df_model
  )
  
  nd <- tibble(
    year_of_manufacture = as.integer(year_of_manufacture),
    engine_size = as.numeric(engine_size),
    mileage = as.numeric(mileage),
    car_age = as.numeric(car_age),
    manufacturer = factor(manufacturer, levels = levels(df_model$manufacturer)),
    fuel_type = factor(fuel_type, levels = levels(df_model$fuel_type))
  )
  
  nd$manufacturer[is.na(nd$manufacturer)] <- factor("Other", levels = levels(df_model$manufacturer))
  nd$fuel_type[is.na(nd$fuel_type)] <- factor("Other", levels = levels(df_model$fuel_type))
  
  pred <- predict(fit, newdata = nd)
  list(predicted_price = round(as.numeric(pred), 2))
}
