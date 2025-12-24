# ===============================================================
#  Car Sales Analytics API
# ===============================================================

library(plumber)
library(DBI)
library(dplyr)
library(jsonlite)

source("db.R")
source("analytics.R")
source("model.R")

# ===============================================================
#  CORS FILTER
# ===============================================================
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Headers", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  forward()
}

# ===============================================================
#  Вспомогательные функции
# ===============================================================

get_df <- function() {
  con <- pg_conn()
  on.exit(dbDisconnect(con), add = TRUE)
  pull_cars(con)
}

# Глобальная модель (живёт пока живёт процесс API)
.MODEL <- NULL

# Инициализация модели при старте API:
# 1) если есть price_model.rds — загрузим
# 2) если нет — попробуем обучить из БД (если там уже есть данные)
.MODEL <- init_model(get_df)

# ===============================================================
#  ENDPOINTS
# ===============================================================

#* Healthcheck
#* @apiTitle Car Sales Analytics API
#* @apiDescription REST API для анализа данных о продаже автомобилей и предсказания их стоимости
#* @apiVersion 1.0
#* @get /health
function() {
  list(
    status = "ok",
    message = "Car Sales API is running",
    model_loaded = !is.null(.MODEL),
    model_file_exists = file.exists(MODEL_PATH)
  )
}

# ---------------------------------------------------------------

#* Загрузка CSV в базу данных PostgreSQL (+ обучение модели и сохранение)
#* @param path:string Путь к CSV-файлу
#* @post /load_data
function(path = "car_sales_data_new_data.csv") {
  n <- load_csv_to_db(path)

  # после загрузки данных — обучим модель и сохраним
  df <- get_df()
  .MODEL <<- train_and_save_model(df)

  list(status = "ok", inserted_rows = n, model_trained = TRUE)
}

# ---------------------------------------------------------------

#* 1️⃣ Статистика по производителям (фильтр по model)
#* @param model:string Модель (опционально)
#* @get /manufacturer_stats
function(model = "") {
  df <- get_df()
  manufacturer_stats(df, model = model)
}

# ---------------------------------------------------------------

#* 2️⃣ Средняя цена по годам (фильтр по manufacturer и model)
#* @param manufacturer:string Производитель (опционально)
#* @param model:string Модель (опционально)
#* @get /year_trend
function(manufacturer = "", model = "") {
  df <- get_df()
  year_trend(df, manufacturer = manufacturer, model = model)
}

# ---------------------------------------------------------------

#* 3️⃣ Соотношение типов топлива (фильтр по manufacturer и model)
#* @param manufacturer:string Производитель (опционально)
#* @param model:string Модель (опционально)
#* @get /fuel_ratio
function(manufacturer = "", model = "") {
  df <- get_df()
  fuel_ratio(df, manufacturer = manufacturer, model = model)
}

# ---------------------------------------------------------------

#* 4️⃣ Распределение по пробегу (фильтр по manufacturer и model)
#* @param manufacturer:string Производитель (опционально)
#* @param model:string Модель (опционально)
#* @get /mileage_distribution
function(manufacturer = "", model = "") {
  df <- get_df()
  mileage_distribution(df, manufacturer = manufacturer, model = model)
}

# ---------------------------------------------------------------

#* 5️⃣ Предсказание стоимости автомобиля (использует сохранённую модель)
#*
#* @param manufacturer:string Производитель
#* @param model:string Модель
#* @param year_of_manufacture:int Год выпуска
#* @param engine_size:double Объём двигателя (л)
#* @param mileage:double Пробег
#* @param fuel_type:string Тип топлива
#* @param sale_year:int Год, в который планируется продать авто
#* @param damages:string Повреждения (PERFECT/SCRATCH/DENT/CRASH/OVERHAUL)
#* @post /predict
function(manufacturer, model, year_of_manufacture, engine_size, mileage, fuel_type, sale_year, damages = "PERFECT") {

  if (is.null(.MODEL)) .MODEL <<- load_model()
  if (is.null(.MODEL)) {
    res$status <- 500
    return(list(
      error = "Модель не обучена",
      hint = "Сначала загрузите данные через /load_data (или положите price_model.rds рядом с проектом)"
    ))
  }

  car_age <- as.numeric(sale_year) - as.numeric(year_of_manufacture)

  man_levels  <- .MODEL$levels$manufacturer
  mdl_levels  <- .MODEL$levels$model
  fuel_levels <- .MODEL$levels$fuel_type

  manufacturer_f <- factor(manufacturer, levels = man_levels)
  model_f        <- factor(model, levels = mdl_levels)
  fuel_f         <- factor(fuel_type, levels = fuel_levels)

  if (is.na(manufacturer_f)) manufacturer_f <- factor("Other", levels = man_levels)
  if (is.na(model_f))        model_f        <- factor("Other", levels = mdl_levels)
  if (is.na(fuel_f))         fuel_f         <- factor("Other", levels = fuel_levels)

  mileage_num <- as.numeric(mileage)
  log_mileage <- log1p(mileage_num)

  nd <- tibble::tibble(
    sale_year = as.numeric(sale_year),
    year_of_manufacture = as.integer(year_of_manufacture),
    engine_size = as.numeric(engine_size),
    mileage = mileage_num,
    log_mileage = log_mileage,
    car_age = as.numeric(car_age),
    manufacturer = manufacturer_f,
    model = model_f,
    fuel_type = fuel_f
  )

  if (!isTRUE(.MODEL$use_sale_year)) {
    nd <- dplyr::select(nd, -sale_year)
  }

  rhs <- delete.response(terms(.MODEL$formula))
  x_new <- model.matrix(rhs, nd)[, -1, drop = FALSE]
  pred_log <- predict(.MODEL$fit, newx = x_new)
  pred <- exp(pred_log)

  dmg_val <- ifelse(is.na(damages) | damages == "", "PERFECT", damages)
  pen <- unname(.MODEL$damage_penalty[[dmg_val]])
  if (is.null(pen) || !is.finite(pen)) pen <- unname(.MODEL$damage_penalty[["Other"]])

  pred <- pred * pen

  list(
    predicted_price = round(as.numeric(pred), 2),
    used_sale_year = isTRUE(.MODEL$use_sale_year),
    computed_car_age = round(car_age, 2),
    damages_penalty = pen
  )
}


# ---------------------------------------------------------------

#* 6️⃣ Популярные модели (фильтр по manufacturer и model)
#* @param manufacturer:string Производитель (опционально)
#* @param model:string Модель (опционально)
#* @get /popular_models
function(manufacturer = "", model = "") {
  df <- get_df()
  popular_models(df, manufacturer = manufacturer, model = model)
}

# ---------------------------------------------------------------

#* 7️⃣ Список производителей (фильтр по model)
#* @param model:string Модель (опционально)
#* @get /manufacturers
function(model = "") {
  df <- get_df()
  manufacturers_list(df, model = model)
}

# ---------------------------------------------------------------

#* 8️⃣ Список типов топлива (фильтр по manufacturer и model)
#* @param manufacturer:string Производитель (опционально)
#* @param model:string Модель (опционально)
#* @get /fuel_types
function(manufacturer = "", model = "") {
  df <- get_df()
  fuel_types_list(df, manufacturer = manufacturer, model = model)
}
