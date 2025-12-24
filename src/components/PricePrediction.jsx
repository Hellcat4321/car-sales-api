import React, { useEffect, useMemo, useState } from "react";
import {
  getManufacturers,
  getFuelTypes,
  predictPrice,
  getManufacturerStats,
  getPopularModels,
} from "../api";

export function PricePrediction() {
  const [manufacturers, setManufacturers] = useState([]);
  const [fuelTypes, setFuelTypes] = useState([]);
  const [models, setModels] = useState([]);
  const [avgForBrand, setAvgForBrand] = useState(null);

  const DAMAGES_OPTIONS = useMemo(
    () => [
      { value: "PERFECT", label: "Идеальное состояние" },
      { value: "SCRATCH", label: "Царапины" },
      { value: "DENT", label: "Вмятины" },
      { value: "CRASH", label: "Был в аварии" },
      { value: "OVERHAUL", label: "Капитальный ремонт" },
    ],
    []
  );

  const [form, setForm] = useState({
    manufacturer: "",
    model: "",
    year_of_manufacture: 2020,
    sale_year: new Date().getFullYear(),
    engine_size: 2.0,
    mileage: 40000,
    fuel_type: "",
    damages: "PERFECT",
  });

  const [predicted, setPredicted] = useState(null);
  const [loading, setLoading] = useState(false);

  const usd = new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  });

  // --- init lists ---
  useEffect(() => {
    (async () => {
      const [mans, fuels, stats] = await Promise.all([
        getManufacturers(),
        getFuelTypes(),
        getManufacturerStats(),
      ]);

      setManufacturers(mans || []);
      setFuelTypes(fuels || []);
      setAvgForBrand(stats || []);

      if ((mans || []).length) {
        setForm((f) => ({ ...f, manufacturer: mans[0] }));
      }
      if ((fuels || []).length) {
        setForm((f) => ({ ...f, fuel_type: fuels[0] }));
      }
    })();
  }, []);

  // --- when manufacturer changes: load models and set MOST popular ---
  useEffect(() => {
    (async () => {
      if (!form.manufacturer) {
        setModels([]);
        setForm((f) => ({ ...f, model: "" }));
        return;
      }

      const rows = await getPopularModels(form.manufacturer, "");
      const safe = Array.isArray(rows) ? rows : [];

      const uniq = Array.from(
        new Set(safe.map((x) => x?.model).filter(Boolean))
      ).sort((a, b) => a.localeCompare(b));
      setModels(uniq);

      const topModel = safe?.[0]?.model ? String(safe[0].model) : "";

      setForm((f) => {
        const cur = f.model ? String(f.model) : "";
        if (cur && uniq.includes(cur)) return f;
        return { ...f, model: topModel };
      });

      setForm((f) => ({ ...f, damages: f.damages || "PERFECT" }));
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form.manufacturer]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
  };

  const toNum = (v, fallback) => {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const payload = {
        manufacturer: String(form.manufacturer || ""),
        model: String(form.model || ""),
        year_of_manufacture: Math.trunc(toNum(form.year_of_manufacture, 2020)),
        sale_year: Math.trunc(toNum(form.sale_year, new Date().getFullYear())),
        engine_size: toNum(form.engine_size, 2.0),
        mileage: toNum(form.mileage, 40000),
        fuel_type: String(form.fuel_type || ""),
        damages: String(form.damages || "PERFECT"),
      };

      const res = await predictPrice(payload);
      setPredicted(res?.predicted_price ?? null);
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
      ? Math.round(Number(predicted) - Number(avgPriceBrand.avg_price))
      : null;

  return (
    <div className="prediction-card">
      <h2>Рассчитать стоимость своей машины</h2>

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
          Модель
          <select name="model" value={form.model} onChange={handleChange}>
            <option value="">{models.length ? "Выберите модель" : "Нет моделей"}</option>
            {models.map((m) => (
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
          Год продажи
          <input
            type="number"
            name="sale_year"
            value={form.sale_year}
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
          Топливо
          <select name="fuel_type" value={form.fuel_type} onChange={handleChange}>
            {fuelTypes.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </label>

        <label>
          Состояние
          <select name="damages" value={form.damages} onChange={handleChange}>
            {DAMAGES_OPTIONS.map((x) => (
              <option key={x.value} value={x.value}>
                {x.label}
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

          <div className="price-main">{usd.format(Number(predicted))}</div>

          <div className="price-meta">
            <span>
              Средняя цена бренда:{" "}
              {avgPriceBrand ? usd.format(Number(avgPriceBrand.avg_price)) : "—"}
            </span>
            <span>
              {diff != null
                ? diff > 0
                  ? `+${usd.format(diff)} к среднему`
                  : `${usd.format(diff)} к среднему`
                : ""}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
