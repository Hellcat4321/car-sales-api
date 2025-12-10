export function BrandTable({ data }) {
  const safeData = Array.isArray(data) ? data : [];
  const sorted = [...safeData].sort((a, b) => {
    const apA = Number(a?.rank_by_avg_price ?? 0);
    const apB = Number(b?.rank_by_avg_price ?? 0);
    return apA - apB;
  });

  return (
    <div className="card card-scroll card-brand">
      <div className="card-header">
        <div>
          <div className="card-title">Brand</div>
          <div className="card-subtitle">Average price &amp; top model</div>
        </div>
      </div>

      <div className="card-scroll-content">
        <table className="brand-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Brand</th>
              <th>Avg price</th>
              <th>Popular model</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((item, i) => {
              const avg = Number(item?.avg_price);
              const formattedPrice =
                !isFinite(avg) || avg <= 0
                  ? "—"
                  : avg.toLocaleString("en-US", {
                      style: "currency",
                      currency: "USD",
                      maximumFractionDigits: 0,
                    });

              return (
                <tr key={item?.manufacturer ?? i}>
                  <td className="brand-rank">
                    {item?.rank_by_avg_price ?? "—"}
                  </td>
                  <td className="brand-name">
                    {item?.manufacturer ?? "Unknown"}
                  </td>
                  <td className="brand-value">{formattedPrice}</td>
                  <td className="brand-value">
                    {item?.popular_model ?? "—"}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
