// src/components/PricePrediction.jsx
import React, { useEffect, useState } from "react";
import {
  getManufacturers,
  getFuelTypes,
  predictPrice,
  getManufacturerStats,
} from "../api";

export function PricePrediction() {
  const [manufacturers, setManufacturers] = useState([]);
  const [fuelTypes, setFuelTypes] = useState([]);
  const [form, setForm] = useState({
    manufacturer: "",
    year_of_manufacture: 2020,
    engine_size: 2.0,
    mileage: 40000,
    car_age: 4,
    fuel_type: "",
  });
  const [predicted, setPredicted] = useState(null);
  const [avgForBrand, setAvgForBrand] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    (async () => {
      const [mans, fuels, stats] = await Promise.all([
        getManufacturers(),
        getFuelTypes(),
        getManufacturerStats(),
      ]);

      setManufacturers(mans);
      setFuelTypes(fuels);

      if (mans.length) {
        setForm((f) => ({ ...f, manufacturer: mans[0] }));
      }
      if (fuels.length) {
        setForm((f) => ({ ...f, fuel_type: fuels[0] }));
      }

      // храним среднюю цену по бренду для расчёта "выше/ниже рынка"
      setAvgForBrand(stats);
    })();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await predictPrice(form);
      setPredicted(res.predicted_price);
    } finally {
      setLoading(false);
    }
  };

  const avgPriceBrand =
    predicted != null && avgForBrand
      ? avgForBrand.find((x) => x.manufacturer === form.manufacturer)
      : null;

  const diff =
    avgPriceBrand && predicted != null
      ? Math.round(predicted - avgPriceBrand.avg_price)
      : null;

  return (
    <div className="prediction-card">
      <h2>S. Рассчитать стоимость своей машины</h2>
      <form className="prediction-form" onSubmit={handleSubmit}>
        <label>
          Производитель
          <select
            name="manufacturer"
            value={form.manufacturer}
            onChange={handleChange}
          >
            {manufacturers.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </label>

        <label>
          Год выпуска
          <input
            type="number"
            name="year_of_manufacture"
            value={form.year_of_manufacture}
            onChange={handleChange}
          />
        </label>

        <label>
          Объём двигателя (л)
          <input
            type="number"
            step="0.1"
            name="engine_size"
            value={form.engine_size}
            onChange={handleChange}
          />
        </label>

        <label>
          Пробег
          <input
            type="number"
            name="mileage"
            value={form.mileage}
            onChange={handleChange}
          />
        </label>

        <label>
          Возраст (лет)
          <input
            type="number"
            name="car_age"
            value={form.car_age}
            onChange={handleChange}
          />
        </label>

        <label>
          Топливо
          <select
            name="fuel_type"
            value={form.fuel_type}
            onChange={handleChange}
          >
            {fuelTypes.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </label>

        <button className="button-primary" type="submit" disabled={loading}>
          {loading ? "Считаю..." : "Предсказать цену"}
        </button>
      </form>

      {predicted != null && (
        <div className="price-result-block">
          <div style={{ fontSize: 11, color: "#a4a4b5" }}>
            Ожидаемая стоимость:
          </div>
          <div className="price-main">
            {predicted.toLocaleString("ru-RU", {
              style: "currency",
              currency: "RUB",
              maximumFractionDigits: 0,
            })}
          </div>
          <div className="price-meta">
            <span>
              Средняя цена бренда:{" "}
              {avgPriceBrand
                ? avgPriceBrand.avg_price.toLocaleString("ru-RU", {
                    style: "currency",
                    currency: "RUB",
                    maximumFractionDigits: 0,
                  })
                : "—"}
            </span>
            <span>
              {diff != null
                ? diff > 0
                  ? `+${diff.toLocaleString("ru-RU")} ₽ к среднему`
                  : `${diff.toLocaleString("ru-RU")} ₽ к среднему`
                : ""}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
