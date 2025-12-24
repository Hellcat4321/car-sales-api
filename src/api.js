import axios from "axios";

const API_BASE = "http://127.0.0.1:8000";

const cleanParams = (params) =>
  Object.fromEntries(
    Object.entries(params).filter(
      ([, v]) => v !== undefined && v !== null && String(v).trim() !== ""
    )
  );

export const getManufacturerStats = async (model = "") => {
  const res = await axios.get(`${API_BASE}/manufacturer_stats`, {
    params: cleanParams({ model }),
  });
  return res.data;
};

export const getYearTrend = async (manufacturer = "", model = "") => {
  const res = await axios.get(`${API_BASE}/year_trend`, {
    params: cleanParams({ manufacturer, model }),
  });
  return res.data;
};

export const getFuelRatio = async (manufacturer = "", model = "") => {
  const res = await axios.get(`${API_BASE}/fuel_ratio`, {
    params: cleanParams({ manufacturer, model }),
  });
  return res.data;
};

export const getMileageDistribution = async (manufacturer = "", model = "") => {
  const res = await axios.get(`${API_BASE}/mileage_distribution`, {
    params: cleanParams({ manufacturer, model }),
  });
  return res.data;
};

export const getPopularModels = async (manufacturer = "", model = "") => {
  const res = await axios.get(`${API_BASE}/popular_models`, {
    params: cleanParams({ manufacturer, model }),
  });
  return res.data;
};

export const getManufacturers = async (model = "") => {
  const res = await axios.get(`${API_BASE}/manufacturers`, {
    params: cleanParams({ model }),
  });
  return res.data;
};

export const getFuelTypes = async (manufacturer = "", model = "") => {
  const res = await axios.get(`${API_BASE}/fuel_types`, {
    params: cleanParams({ manufacturer, model }),
  });
  return res.data;
};

export const predictPrice = async (params) => {
  const res = await axios.post(`${API_BASE}/predict`, null, {
    params: cleanParams(params),
  });
  return res.data;
};
