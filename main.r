# main.R
# 🚀 Точка входа в проект Car Sales API

# Подключаем plumber и зависимости
library(plumber)

# Загружаем основной API
pr <- plumber::pr("api.R")

# Запускаем сервер
pr$run(host = "0.0.0.0", port = 8000)