import axios from "axios";

const API_BASE = "http://127.0.0.1:8000";

export const getManufacturerStats = async () => {
  const res = await axios.get(`${API_BASE}/manufacturer_stats`);
  return res.data;
};

export const getYearTrend = async (manufacturer = "") => {
  const res = await axios.get(`${API_BASE}/year_trend`, {
    params: { manufacturer },
  });
  return res.data;
};

export const getFuelRatio = async (manufacturer = "") => {
  const res = await axios.get(`${API_BASE}/fuel_ratio`, {
    params: { manufacturer },
  });
  return res.data;
};

export const getMileageDistribution = async () => {
  const res = await axios.get(`${API_BASE}/mileage_distribution`);
  return res.data;
};

export const getPopularModels = async () => {
  const res = await axios.get(`${API_BASE}/popular_models`);
  return res.data;
};


export const getManufacturers = async () => {
  const res = await axios.get(`${API_BASE}/manufacturers`);
  return res.data;
};

export const getFuelTypes = async () => {
  const res = await axios.get(`${API_BASE}/fuel_types`);
  return res.data;
};

export const predictPrice = async (params) => {
  const res = await axios.post(`${API_BASE}/predict`, null, { params });
  return res.data;
};
