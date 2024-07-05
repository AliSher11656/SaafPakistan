const express = require("express");
const Order = require("../controller/orders");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/orders/:id?", firebaseAuth, Order.getOrders);
router.get("/users/:id", firebaseAuth, Order.getUserOrders);
router.get("/rider/:id", firebaseAuth, Order.getRiderOrders);
router.delete("/users/:id/:deleteId", firebaseAuth, Order.deleteOrder);
router.put("/rider/:id/:orderId", firebaseAuth, Order.updateRiderOrder);

// router.post("/orders", firebaseAuth, Order.createOrder);
// router.put("/orders/:id", firebaseAuth, Order.updateOrder);

module.exports = router;
