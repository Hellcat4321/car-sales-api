export function PopularModelsChart({ data }) {
  const safeData = Array.isArray(data) ? data : [];
  const maxCount = safeData.reduce(
    (acc, x) => Math.max(acc, x.count_sold || 0),
    0
  );

  return (
    <div className="card card-scroll card-popular">
      <div className="card-header">
        <div className="card-title">Популярные модели автомобилей</div>
      </div>

      <div className="card-scroll-content">
        <div className="popular-models-list">
          {safeData.map((item, idx) => {
            const width = maxCount ? (item.count_sold / maxCount) * 100 : 0;
            return (
              <div
                className="popular-model-row"
                key={`${item.manufacturer}-${item.model}-${idx}`}
              >
                <div className="popular-model-name">{item.model}</div>
                <div className="popular-model-bar-wrapper">
                  <div
                    className="popular-model-bar"
                    style={{ width: `${width}%` }}
                  />
                </div>
                <div className="popular-model-count">
                  {item.count_sold}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
