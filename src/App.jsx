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

  useEffect(() => {
    (async () => {
      const stats = await getManufacturerStats();
      setManufacturerStats(stats);

      if (stats && stats.length)
        setSelectedManufacturer(stats[0].manufacturer);

      const [mileage, popular] = await Promise.all([
        getMileageDistribution(),
        getPopularModels(),
      ]);

      setMileageDistribution(mileage);
      setPopularModels(popular);
    })();
  }, []);

  useEffect(() => {
    (async () => {
      const [trend, fuel] = await Promise.all([
        getYearTrend(selectedManufacturer),
        getFuelRatio(selectedManufacturer),
      ]);

      setYearTrend(trend);
      setFuelRatio(fuel);
    })();
  }, [selectedManufacturer]);

  return (
    <div className="app-root">
      <div className="dashboard">

        {/* HEADER */}
        <header className="dashboard-header">
          <div className="dashboard-title">
            <div className="dashboard-icon"></div>
            <div>
              <h1>Car Sales Analytics Dashboard</h1>
              <span>Real-time insights for used car market</span>
            </div>
          </div>

          <div className="header-actions">
            <select
              className="select-compact"
              value={selectedManufacturer}
              onChange={(e) => setSelectedManufacturer(e.target.value)}
            >
              <option value="">Все производители</option>
              {manufacturerStats.map((m) => (
                <option key={m.manufacturer} value={m.manufacturer}>
                  {m.manufacturer}
                </option>
              ))}
            </select>
            <button className="icon-button">⚙️</button>
            <button className="icon-button">≡</button>
          </div>
        </header>

        {/* GRID */}
        <div className="dashboard-grid">

          {/* LEFT COLUMN */}
          <div className="left-column">
            <BrandTable data={manufacturerStats} />
            <PopularModelsChart data={popularModels} />
          </div>

          {/* MIDDLE */}
          <div>
            <YearTrendChart data={yearTrend} />
            <div className="pies-row" style={{ marginTop: 14 }}>
              <FuelPie data={fuelRatio} />
              <MileagePie data={mileageDistribution} />
            </div>
          </div>

          {/* RIGHT */}
          <div>
            <PricePrediction />
          </div>

        </div>

      </div>
    </div>
  );
}
