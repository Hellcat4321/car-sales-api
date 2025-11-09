# ===============================================================
#  Car Sales Analytics API
#  Powered by plumber, PostgreSQL, R
#  Swagger UI: http://127.0.0.1:8000/__docs__/
# ===============================================================

library(plumber)
library(DBI)
library(dplyr)
library(jsonlite)

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
#* Возвращает таблицу с агрегированными показателями по каждому производителю:
#* - средняя цена продажи (`avg_price`)
#* - количество проданных машин (`count_sold`)
#* - самая популярная модель (`popular_model`)
#* - ранги по средней цене и количеству
#*
#* @get /manufacturer_stats
#* @response 200 {array} list Список производителей с их статистикой
#* @response 500 Ошибка при анализе данных
function() {
  df <- get_df()
  res <- manufacturer_stats(df)
  toJSON(res, dataframe = "rows", auto_unbox = TRUE, na = "null")
}

# ---------------------------------------------------------------

#* 2️⃣ Средняя цена по годам выпуска
#* 
#* Возвращает динамику средней цены автомобилей по годам выпуска.
#* Можно указать конкретного производителя.
#*
#* @param manufacturer:string Название производителя (опционально)
#* @get /year_trend
#* @response 200 {array} list Массив объектов {year_of_manufacture, avg_price}
#* @response 500 Ошибка при построении графика
function(manufacturer = "") {
  df <- get_df()
  res <- year_trend(df, manufacturer)
  toJSON(res, dataframe = "rows", auto_unbox = TRUE, na = "null")
}

# ---------------------------------------------------------------

#* 3️⃣ Соотношение типов топлива
#*
#* Возвращает круговую диаграмму распределения типов топлива
#* (в процентах) для всех производителей или выбранного.
#*
#* @param manufacturer:string Название производителя (опционально)
#* @get /fuel_ratio
#* @response 200 {array} list Массив объектов {fuel_type, percent}
#* @response 500 Ошибка при анализе данных
function(manufacturer = "") {
  df <- get_df()
  res <- fuel_ratio(df, manufacturer)
  toJSON(res, dataframe = "rows", auto_unbox = TRUE, na = "null")
}

# ---------------------------------------------------------------

#* 4️⃣ Распределение по пробегу
#*
#* Возвращает категории пробега автомобилей и процент каждой группы:
#* - 0–50k  
#* - 50–100k  
#* - 100–150k  
#* - 150–200k  
#* - 200–250k  
#* - 250k+
#*
#* @get /mileage_distribution
#* @response 200 {array} list Массив объектов {range, percent}
#* @response 500 Ошибка при анализе данных
function() {
  df <- get_df()
  res <- mileage_distribution(df)
  toJSON(res, dataframe = "rows", auto_unbox = TRUE, na = "null")
}

# ---------------------------------------------------------------

#* 5️⃣ Предсказание стоимости автомобиля
#*
#* Строит модель линейной регрессии по историческим данным и
#* прогнозирует стоимость автомобиля на основе введённых параметров.
#*
#* Входные параметры:
#* - `manufacturer` (строка): производитель  
#* - `year_of_manufacture` (число): год выпуска  
#* - `engine_size` (число): объём двигателя (литры)  
#* - `mileage` (число): пробег (в милях или км, как в CSV)  
#* - `car_age` (число): возраст автомобиля  
#* - `fuel_type` (строка): тип топлива (Diesel, Petrol и т.д.)
#*
#* Пример запроса:
#* ```
#* POST /predict?manufacturer=Toyota&year_of_manufacture=2017&engine_size=1.8&mileage=50000&car_age=6&fuel_type=Petrol
#* ```
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
  res <- predict_price(
    df,
    manufacturer,
    year_of_manufacture,
    engine_size,
    mileage,
    car_age,
    fuel_type
  )
  toJSON(res, auto_unbox = TRUE, na = "null")
}
