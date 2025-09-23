const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

router.post('/stkpush', paymentController.stkPush);
router.post('/callback', paymentController.stkCallback);

module.exports = router;
