const express = require("express");
const Payment = require("../controller/payments");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get(
  "/payment",
  //  firebaseAuth,
  Payment.getCompletedOrders
);

module.exports = router;
