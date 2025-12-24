import React, { useEffect, useState } from "react";
import "./styles.css";
import {
  getManufacturerStats,
  getYearTrend,
  getFuelRatio,
  getMileageDistribution,
  getPopularModels,
} from "./api";

import { BrandTable } from "./components/BrandTable";
import { PopularModelsChart } from "./components/PopularModelsChart";
import { YearTrendChart } from "./components/YearTrendChart";
import { FuelPie } from "./components/FuelPie";
import { MileagePie } from "./components/MileagePie";
import { PricePrediction } from "./components/PricePrediction";

export default function App() {
  const [manufacturerStats, setManufacturerStats] = useState([]);
  const [yearTrend, setYearTrend] = useState([]);
  const [fuelRatio, setFuelRatio] = useState([]);
  const [mileageDistribution, setMileageDistribution] = useState([]);
  const [popularModels, setPopularModels] = useState([]);

  const [selectedManufacturer, setSelectedManufacturer] = useState("");
  const [selectedModel, setSelectedModel] = useState("");
  const [modelsList, setModelsList] = useState([]);

  // init
  useEffect(() => {
    (async () => {
      const [stats, trend, fuel, mileage, popularAll] = await Promise.all([
        getManufacturerStats(""),
        getYearTrend("", ""),
        getFuelRatio("", ""),
        getMileageDistribution("", ""),
        getPopularModels("", ""),
      ]);

      setManufacturerStats(stats);
      setYearTrend(trend);
      setFuelRatio(fuel);
      setMileageDistribution(mileage);
      setPopularModels(popularAll);

      const uniq = Array.from(
        new Set((popularAll || []).map((x) => x?.model).filter(Boolean))
      ).sort((a, b) => a.localeCompare(b));

      setModelsList(uniq);
    })();
  }, []);

  // manufacturer -> models list
  useEffect(() => {
    (async () => {
      if (!selectedManufacturer) {
        const allRows = await getPopularModels("", "");
        const allUniq = Array.from(
          new Set((allRows || []).map((x) => x?.model).filter(Boolean))
        ).sort((a, b) => a.localeCompare(b));
        setModelsList(allUniq);
        return;
      }

      const rows = await getPopularModels(selectedManufacturer, "");
      const uniq = Array.from(
        new Set((rows || []).map((x) => x?.model).filter(Boolean))
      ).sort((a, b) => a.localeCompare(b));

      setModelsList(uniq);

      if (selectedModel && !uniq.includes(selectedModel)) {
        setSelectedModel("");
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedManufacturer]);

  // filters -> reload widgets
  useEffect(() => {
    (async () => {
      const [stats, trend, fuel, mileage, popular] = await Promise.all([
        getManufacturerStats(selectedModel),
        getYearTrend(selectedManufacturer, selectedModel),
        getFuelRatio(selectedManufacturer, selectedModel),
        getMileageDistribution(selectedManufacturer, selectedModel),
        getPopularModels(selectedManufacturer, selectedModel),
      ]);

      setManufacturerStats(stats);
      setYearTrend(trend);
      setFuelRatio(fuel);
      setMileageDistribution(mileage);
      setPopularModels(popular);
    })();
  }, [selectedManufacturer, selectedModel]);

  return (
    <div className="app-root">
      <div className="dashboard">
        <header className="dashboard-header">
          <div className="dashboard-title">
            <div>
              <h1>Аналитика рынка автомобилей</h1>
            </div>
          </div>

          <div className="header-actions">
            <select
              className="select-compact"
              value={selectedManufacturer}
              onChange={(e) => setSelectedManufacturer(e.target.value)}
            >
              <option value="">Все производители</option>
              {(manufacturerStats || []).map((m) => (
                <option key={m.manufacturer} value={m.manufacturer}>
                  {m.manufacturer}
                </option>
              ))}
            </select>

            <select
              className="select-compact"
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
            >
              <option value="">Все модели</option>
              {(modelsList || []).map((model) => (
                <option key={model} value={model}>
                  {model}
                </option>
              ))}
            </select>
          </div>
        </header>

        {/* GRID */}
        <div className="dashboard-grid">
          <div className="left-column">
            <BrandTable data={manufacturerStats} />
            <PopularModelsChart data={popularModels} />
          </div>

          <div className="middle-column">
            <YearTrendChart data={yearTrend} />
            <div className="pies-row">
              <FuelPie data={fuelRatio} />
              <MileagePie data={mileageDistribution} />
            </div>
          </div>

          <div className="right-column">
            <PricePrediction />
          </div>
        </div>
      </div>
    </div>
  );
}
