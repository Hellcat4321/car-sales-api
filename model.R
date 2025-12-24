# model.R
library(dplyr)
library(forcats)
library(glmnet)

MODEL_PATH <- "price_model.rds"

# ========== Подготовка данных ==========
prep_train_df <- function(df) {
  df <- df %>%
    filter(
      price > 0,
      mileage >= 0,
      engine_size > 0,
      year_of_manufacture > 1950,
      !is.na(manufacturer),
      !is.na(model),
      !is.na(fuel_type)
    ) %>%
    mutate(
      damages = ifelse(is.na(damages) | damages == "", "PERFECT", damages),
      log_price = log(price),
      log_mileage = log1p(mileage)
    )

  # восстановление года продажи (если есть car_age)
  if ("car_age" %in% names(df)) {
    df <- df %>%
      mutate(
        sale_year = ifelse(!is.na(car_age), year_of_manufacture + round(car_age), NA_real_)
      )
  } else {
    df$sale_year <- NA_real_
  }

  # легкий отсев выбросов по log_price
  q1 <- quantile(df$log_price, 0.25, na.rm = TRUE)
  q3 <- quantile(df$log_price, 0.75, na.rm = TRUE)
  iqr <- q3 - q1

  df %>%
    filter(
      log_price >= (q1 - 3 * iqr),
      log_price <= (q3 + 3 * iqr)
    )
}

# ========== Обучение и сохранение ==========
train_and_save_model <- function(df, model_path = MODEL_PATH) {
  set.seed(42)

  df_model <- prep_train_df(df) %>%
    mutate(
      manufacturer = fct_lump(factor(manufacturer), n = 15, other_level = "Other"),
      model        = fct_lump(factor(model), n = 30, other_level = "Other"),
      fuel_type    = fct_lump(factor(fuel_type), n = 10, other_level = "Other"),
      damages      = fct_lump(factor(damages), n = 10, other_level = "Other")
    )

  # train/valid
  n <- nrow(df_model)
  idx <- sample(seq_len(n), size = floor(0.8 * n))
  train <- df_model[idx, ]
  valid <- df_model[-idx, ]

  use_sale_year <- sum(!is.na(train$sale_year)) > 20

  # ВАЖНО: damages НЕ включаем в ML, будем применять штраф после предсказания
  if (use_sale_year) {
    fml <- log_price ~ sale_year + year_of_manufacture + engine_size +
      log_mileage + manufacturer + model + fuel_type
  } else {
    fml <- log_price ~ year_of_manufacture + engine_size +
      log_mileage + manufacturer + model + fuel_type
  }

  x_train <- model.matrix(fml, train)[, -1, drop = FALSE]
  y_train <- train$log_price

  x_valid <- model.matrix(fml, valid)[, -1, drop = FALSE]
  y_valid <- valid$log_price

  cv <- cv.glmnet(x_train, y_train, alpha = 0, nfolds = 5)
  fit <- glmnet(x_train, y_train, alpha = 0, lambda = cv$lambda.min)

  pred_log <- predict(fit, newx = x_valid)
  pred <- exp(pred_log)
  actual <- exp(y_valid)

  rmse <- sqrt(mean((pred - actual)^2, na.rm = TRUE))
  r2 <- 1 - sum((pred - actual)^2) / sum((actual - mean(actual))^2)

  cat("\n=========== RIDGE MODEL QUALITY ===========\n")
  cat("Rows total      :", n, "\n")
  cat("Rows train      :", nrow(train), "\n")
  cat("Rows validation :", nrow(valid), "\n")
  cat("RMSE (USD)      :", round(rmse, 0), "\n")
  cat("R²              :", round(r2, 4), "\n")
  cat("Lambda          :", round(cv$lambda.min, 6), "\n")
  cat("Sale year used  :", use_sale_year, "\n")
  cat("==========================================\n\n")

  damage_penalty <- c(
    PERFECT  = 1,
    SCRATCH  = 0.95,
    DENT     = 0.9,
    OVERHAUL = 0.7,
    CRASH    = 0.8,
    Other    = 0.9
  )

  payload <- list(
    fit = fit,
    formula = fml,
    use_sale_year = use_sale_year,
    levels = list(
      manufacturer = levels(df_model$manufacturer),
      model        = levels(df_model$model),
      fuel_type    = levels(df_model$fuel_type),
      damages      = levels(df_model$damages)
    ),
    damage_penalty = damage_penalty,
    metrics = list(rmse = rmse, r2 = r2)
  )

  saveRDS(payload, model_path)
  payload
}

# ========== Загрузка/инициализация ==========
load_model <- function(model_path = MODEL_PATH) {
  if (!file.exists(model_path)) return(NULL)
  readRDS(model_path)
}

init_model <- function(get_df_fun, model_path = MODEL_PATH) {
  m <- load_model(model_path)
  if (!is.null(m)) return(m)

  df <- get_df_fun()
  if (nrow(df) == 0) return(NULL)

  train_and_save_model(df, model_path)
}
