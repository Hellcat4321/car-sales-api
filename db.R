# db.R
library(DBI)
library(RPostgres)
library(dplyr)
library(readr)
library(stringr)

pg_conn <- function() {
  dbConnect(
    RPostgres::Postgres(),
    host = "localhost",
    port = 5432,
    dbname = "car_sales_db",
    user = "postgres",
    password = "postgres"
  )
}

ensure_table <- function(con) {
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS cars (
      id SERIAL PRIMARY KEY,
      manufacturer TEXT,
      model TEXT,
      engine_size DOUBLE PRECISION,
      fuel_type TEXT,
      year_of_manufacture INT,
      mileage DOUBLE PRECISION,
      price DOUBLE PRECISION,
      car_age DOUBLE PRECISION,
      damages TEXT
    );
  ")
}

normalize_cols <- function(df) {
  names(df) <- names(df) |>
    tolower() |>
    str_replace_all("\\s+", "_") |>
    str_replace_all("[^a-z0-9_]", "")
  df
}

coerce_schema <- function(df) {
  req <- c("manufacturer","model","engine_size","fuel_type",
           "year_of_manufacture","mileage","price","car_age","damages")
  miss <- setdiff(req, names(df))
  if (length(miss) > 0) {
    stop(paste0("В CSV отсутствуют колонки: ", paste(miss, collapse = ", ")))
  }
  df <- df |> dplyr::select(all_of(req))
  df |> mutate(
    manufacturer = as.character(manufacturer),
    model = as.character(model),
    engine_size = as.numeric(engine_size),
    fuel_type = as.character(fuel_type),
    year_of_manufacture = as.integer(year_of_manufacture),
    mileage = as.numeric(mileage),
    price = as.numeric(price),
    car_age = as.numeric(car_age),
    damages = as.character(damages)
  )
}

load_csv_to_db <- function(csv_path) {
  con <- pg_conn()
  on.exit(dbDisconnect(con), add = TRUE)
  ensure_table(con)
  df <- readr::read_csv(csv_path, show_col_types = FALSE) |>
    normalize_cols() |>
    coerce_schema()
  df <- df |> filter(!is.na(price), !is.na(mileage))
  dbAppendTable(con, "cars", df)
  invisible(nrow(df))
}

pull_cars <- function(con) {
  as_tibble(dbReadTable(con, "cars"))
}
