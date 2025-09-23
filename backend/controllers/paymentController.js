const axios = require('axios');
const Payment = require('../models/Payment');
const { getAccessToken, getPassword, getTimestamp } = require('../utils/mpesaUtils');
const mpesaConfig = require('../config/mpesaConfig');

// STK Push
exports.stkPush = async (req, res) => {
  const { userId, phone, amount } = req.body;

  try {
    const token = await getAccessToken();
    const { password, timestamp } = getPassword();

    const stkData = {
      BusinessShortCode: mpesaConfig.shortCode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,
      PartyB: mpesaConfig.shortCode,
      PhoneNumber: phone,
      CallBackURL: mpesaConfig.callbackUrl,
      AccountReference: `JobPortal-${userId}`,
      TransactionDesc: 'Job application fee',
    };

    await axios.post('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest', stkData, {
      headers: { Authorization: `Bearer ${token}` },
    });

    // Save pending payment
    const payment = new Payment({ userId, phone, amount, status: 'pending' });
    await payment.save();

    res.status(200).json({ message: 'STK Push initiated', paymentId: payment._id });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'STK Push failed' });
  }
};

// Callback from Safaricom
exports.stkCallback = async (req, res) => {
  const callbackData = req.body;

  // Extract transaction info
  try {
    const result = callbackData.Body.stkCallback;
    const checkoutRequestId = result.CheckoutRequestID;
    const status = result.ResultCode === 0 ? 'success' : 'failed';
    const transactionId = result.CallbackMetadata ? result.CallbackMetadata.Item.find(i => i.Name === 'MpesaReceiptNumber').Value : null;

    await Payment.findOneAndUpdate({ _id: checkoutRequestId }, { status, transactionId });

    res.status(200).json({ message: 'Callback received' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Callback error' });
  }
};
