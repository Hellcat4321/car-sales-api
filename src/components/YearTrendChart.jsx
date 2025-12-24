// src/components/YearTrendChart.jsx
import React from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

export function YearTrendChart({ data }) {
  return (
    <div className="card card-yeartrend">
      <div className="card-header">
        <div className="card-title">Средняя цена по годам</div>
      </div>

      <div className="chart-wrapper chart-wrapper-line">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data || []} margin={{ top: 10, right: 10, left: 0 }}>
            <XAxis
              dataKey="year_of_manufacture"
              stroke="#707089"
              fontSize={11}
            />
            <YAxis
              stroke="#707089"
              fontSize={11}
              tickFormatter={(v) => `$${Math.round(v / 1000)}k`}
            />
            <Tooltip
              contentStyle={{
                background: "#14141f",
                border: "1px solid #2a2a3a",
                color: "#fff",
                fontSize: 11,
              }}
              formatter={(value) =>
                value.toLocaleString("en-US", {
                  style: "currency",
                  currency: "USD",
                  maximumFractionDigits: 0,
                })
              }
              labelFormatter={(lab) => `Year: ${lab}`}
            />
            <Line
              type="monotone"
              dataKey="avg_price"
              stroke="#ff2e2e"
              strokeWidth={2}
              dot={false}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
