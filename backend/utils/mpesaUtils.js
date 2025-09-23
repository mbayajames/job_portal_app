const axios = require('axios');
const mpesaConfig = require('../config/mpesaConfig');
const base64 = require('base-64');

async function getAccessToken() {
  const auth = base64.encode(`${mpesaConfig.consumerKey}:${mpesaConfig.consumerSecret}`);
  const response = await axios.get('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials', {
    headers: { Authorization: `Basic ${auth}` },
  });
  return response.data.access_token;
}

function getTimestamp() {
  const date = new Date();
  const y = date.getFullYear();
  const m = ('0' + (date.getMonth() + 1)).slice(-2);
  const d = ('0' + date.getDate()).slice(-2);
  const h = ('0' + date.getHours()).slice(-2);
  const min = ('0' + date.getMinutes()).slice(-2);
  const s = ('0' + date.getSeconds()).slice(-2);
  return `${y}${m}${d}${h}${min}${s}`;
}

function getPassword() {
  const timestamp = getTimestamp();
  const password = base64.encode(`${mpesaConfig.shortCode}${mpesaConfig.passkey}${timestamp}`);
  return { password, timestamp };
}

module.exports = { getAccessToken, getPassword, getTimestamp };
