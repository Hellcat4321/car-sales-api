# ===============================================================
#  Car Sales Analytics API
#  Powered by plumber, PostgreSQL, R
#  Swagger UI: http://127.0.0.1:8000/__docs__/
# ===============================================================

library(plumber)
library(DBI)
library(dplyr)
library(jsonlite)

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

source("db.R")
source("analytics.R")

# ===============================================================
#  Вспомогательные функции
# ===============================================================

get_df <- function() {
  con <- pg_conn()
  on.exit(dbDisconnect(con), add = TRUE)
  pull_cars(con)
}

# ===============================================================
#  ENDPOINTS
# ===============================================================

#* Healthcheck — проверка, что API работает
#* @apiTitle Car Sales Analytics API
#* @apiDescription REST API для анализа данных о продаже автомобилей и предсказания их стоимости
#* @apiVersion 1.0
#* @get /health
#* @response 200 Сервис запущен успешно
function() {
  list(status = "ok", message = "Car Sales API is running")
}

# ---------------------------------------------------------------

#* Загрузка CSV в базу данных PostgreSQL
#* @param path:string Путь к CSV-файлу (по умолчанию 'car_sales_data_new_data.csv')
#* @post /load_data
#* @response 200 {object} list Возвращает статус и количество добавленных строк
#* @response 500 Ошибка при загрузке данных
function(path = "car_sales_data_new_data.csv") {
  n <- load_csv_to_db(path)
  list(status = "ok", inserted_rows = n)
}

# ---------------------------------------------------------------

#* 1️⃣ Статистика по производителям
#*
#* @get /manufacturer_stats
#* @response 200 {array} list Список производителей с их статистикой
#* @response 500 Ошибка при анализе данных
function() {
  df <- get_df()
  manufacturer_stats(df)
}

# ---------------------------------------------------------------

#* 2️⃣ Средняя цена по годам выпуска
#*
#* @param manufacturer:string Название производителя (опционально)
#* @get /year_trend
#* @response 200 {array} list Массив объектов {year_of_manufacture, avg_price}
#* @response 500 Ошибка при построении графика
function(manufacturer = "") {
  df <- get_df()
  year_trend(df, manufacturer)
}

# ---------------------------------------------------------------

#* 3️⃣ Соотношение типов топлива
#*
#* @param manufacturer:string Название производителя (опционально)
#* @get /fuel_ratio
#* @response 200 {array} list Массив объектов {fuel_type, percent}
#* @response 500 Ошибка при анализе данных
function(manufacturer = "") {
  df <- get_df()
  fuel_ratio(df, manufacturer)
}

# ---------------------------------------------------------------

#* 4️⃣ Распределение по пробегу
#*
#* @get /mileage_distribution
#* @response 200 {array} list Массив объектов {mileage_group, percent}
#* @response 500 Ошибка при анализе данных
function() {
  df <- get_df()
  mileage_distribution(df)
}

# ---------------------------------------------------------------

#* 5️⃣ Предсказание стоимости автомобиля
#*
#* @param manufacturer:string Производитель
#* @param year_of_manufacture:int Год выпуска
#* @param engine_size:double Объём двигателя (л)
#* @param mileage:double Пробег
#* @param car_age:double Возраст автомобиля
#* @param fuel_type:string Тип топлива
#* @post /predict
#* @response 200 {object} list Объект с предсказанной ценой {predicted_price}
#* @response 500 Ошибка при обучении или предсказании модели
function(manufacturer, year_of_manufacture, engine_size, mileage, car_age, fuel_type) {
  df <- get_df()
  predict_price(
    df,
    manufacturer,
    year_of_manufacture,
    engine_size,
    mileage,
    car_age,
    fuel_type
  )
}

# ---------------------------------------------------------------

#* 6️⃣ Популярные модели автомобилей
#*
#* @param limit:int (игнорируется, для совместимости)
#* @get /popular_models
function(limit = 10) {
  df <- get_df()
  popular_models(df)
}


# ---------------------------------------------------------------

#* 7️⃣ Список производителей
#*
#* @get /manufacturers
#* @response 200 {array} list Массив строк — названия производителей
function() {
  df <- get_df()
  manufacturers_list(df)
}

# ---------------------------------------------------------------

#* 8️⃣ Список типов топлива
#*
#* @get /fuel_types
#* @response 200 {array} list Массив строк — типы топлива
function() {
  df <- get_df()
  fuel_types_list(df)
}
