# model.R
library(DBI)
library(dplyr)
library(forcats)

MODEL_PATH <- "price_model.rds"

# Проверяем, есть ли данные в таблице
db_has_data <- function(con) {
  if (!dbExistsTable(con, "cars")) return(FALSE)
  n <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM cars;")$n[1]
  isTRUE(n > 0)
}

# Готовим данные к обучению
prep_train_df <- function(df) {
  df <- df %>%
    filter(
      !is.na(price),
      !is.na(mileage),
      !is.na(engine_size),
      !is.na(year_of_manufacture),
      !is.na(fuel_type),
      !is.na(manufacturer),
      !is.na(model)
    )

  # Если в датасете есть car_age, восстановим "год продажи" как year + car_age
  # Если car_age нет/NA — оставим NA, модель всё равно будет учиться на остальном
  if (!("car_age" %in% names(df))) df$car_age <- NA_real_

  df <- df %>%
    mutate(
      sale_year = ifelse(!is.na(car_age), year_of_manufacture + round(car_age), NA_real_),
      damages = ifelse(is.na(damages) | damages == "", "None", damages)
    )

  df
}

# Обучение модели (один раз), сохранение на диск
train_and_save_model <- function(df, model_path = MODEL_PATH) {
  df_model <- prep_train_df(df) %>%
    mutate(
      manufacturer = fct_lump(factor(manufacturer), n = 15, other_level = "Other"),
      fuel_type     = fct_lump(factor(fuel_type), n = 10, other_level = "Other"),
      damages       = fct_lump(factor(damages), n = 15, other_level = "Other")
    )

  # Важно: sale_year может быть NA — lm это переварит, но часть строк выкинет.
  # Если sale_year почти весь NA — просто не используем его.
  use_sale_year <- sum(!is.na(df_model$sale_year)) > 20

  if (use_sale_year) {
    fit <- lm(
      price ~ sale_year + year_of_manufacture + engine_size + mileage + manufacturer + fuel_type + damages,
      data = df_model
    )
  } else {
    fit <- lm(
      price ~ year_of_manufacture + engine_size + mileage + manufacturer + fuel_type + damages,
      data = df_model
    )
  }

  payload <- list(
    fit = fit,
    use_sale_year = use_sale_year,
    levels = list(
      manufacturer = levels(df_model$manufacturer),
      fuel_type = levels(df_model$fuel_type),
      damages = levels(df_model$damages)
    )
  )

  saveRDS(payload, model_path)
  payload
}

# Загрузка модели из файла
load_model <- function(model_path = MODEL_PATH) {
  if (!file.exists(model_path)) return(NULL)
  readRDS(model_path)
}

# Инициализация: если есть файл — грузим, если нет — пробуем обучить из БД
init_model <- function(get_df_fun, model_path = MODEL_PATH) {
  m <- load_model(model_path)
  if (!is.null(m)) return(m)

  df <- get_df_fun()
  if (nrow(df) == 0) return(NULL)

  train_and_save_model(df, model_path)
}
