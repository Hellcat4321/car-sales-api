import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

const COLORS = ["#ff2e2e", "#f5a623", "#5b8def", "#6dd3c9", "#9c27b0", "#607d8b"];

export function MileagePie({ data }) {
  // Безопасная нормализация входных данных
  const safeData = Array.isArray(data)
    ? data.map(x => ({
        mileage_group: x?.mileage_group ?? "Unknown",
        percent: isNaN(Number(x?.percent)) ? 0 : Number(x.percent)
      }))
    : [];

  const total = safeData.reduce((sum, x) => sum + x.percent, 0);

  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title">Пробег</div>
      </div>

      <div className="chart-wrapper">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={safeData}
              dataKey="percent"
              nameKey="mileage_group"
              innerRadius={50}
              outerRadius={80}
              paddingAngle={2}
            >
              {safeData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
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
          {isFinite(total) ? `${total.toFixed(1)}%` : "0%"}
        </div>
      </div>

      <div className="pie-legend">
        {safeData.length === 0
          ? "Нет данных"
          : safeData
              .map((x) => `${x.mileage_group}: ${x.percent.toFixed(1)}%`)
              .join(" • ")}
      </div>
    </div>
  );
}
