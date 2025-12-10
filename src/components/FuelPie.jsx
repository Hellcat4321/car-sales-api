import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

const COLORS = ["#ff2e2e", "#f5a623", "#5b8def", "#6dd3c9", "#9c27b0"];

export function FuelPie({ data }) {
  // fallback если API прислал undefined/null
  const safeData = Array.isArray(data)
    ? data.map(x => ({
        fuel_type: x.fuel_type ?? "Unknown",
        percent: isNaN(Number(x.percent)) ? 0 : Number(x.percent)
      }))
    : [];

  const total = safeData.reduce((s, x) => s + x.percent, 0);

  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title">Топливо</div>
      </div>

      <div className="chart-wrapper">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={safeData}
              dataKey="percent"
              nameKey="fuel_type"
              innerRadius={50}
              outerRadius={80}
              paddingAngle={2}
            >
              {safeData.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}
            </Pie>

            <Tooltip
              contentStyle={{
                background: "#14141f",
                border: "1px solid #2a2a3a",
                fontSize: 11,
              }}
              formatter={(v, name) => [`${Number(v).toFixed(1)}%`, name]}
            />
          </PieChart>
        </ResponsiveContainer>

        <div className="pie-center-label">
          {total ? `${total.toFixed(1)}%` : "0%"}
        </div>
      </div>

      <div className="pie-legend">
        {safeData.length === 0
          ? "Нет данных"
          : safeData
              .map((x) => `${x.fuel_type}: ${x.percent.toFixed(1)}%`)
              .join(" • ")}
      </div>
    </div>
  );
}
