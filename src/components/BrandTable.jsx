export function BrandTable({ data }) {
  const safeData = Array.isArray(data) ? data : [];
  const sorted = [...safeData].sort((a, b) => {
    const apA = Number(a?.rank_by_avg_price ?? 0);
    const apB = Number(b?.rank_by_avg_price ?? 0);
    return apA - apB;
  });

  const usd = new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  });

  return (
    <div className="card card-scroll card-brand">
      <div className="card-header">
        <div>
          <div className="card-title">Производитель</div>
        </div>
      </div>

      <div className="card-scroll-content">
        <table className="brand-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Производитель</th>
              <th>Средняя цена</th>
              <th>Самая популярная модель</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((item, i) => {
              const avg = Number(item?.avg_price);
              const formattedPrice =
                !isFinite(avg) || avg <= 0 ? "—" : usd.format(avg);

              return (
                <tr key={item?.manufacturer ?? i}>
                  <td className="brand-rank">{item?.rank_by_avg_price ?? "—"}</td>
                  <td className="brand-name">{item?.manufacturer ?? "Unknown"}</td>
                  <td className="brand-value">{formattedPrice}</td>
                  <td className="brand-value">{item?.popular_model ?? "—"}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
