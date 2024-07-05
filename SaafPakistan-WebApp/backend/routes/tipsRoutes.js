const express = require("express");
const Tips = require("../controller/tips");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/tips", firebaseAuth, Tips.getTips);
router.post("/tips", firebaseAuth, Tips.createTip);
router.put("/tips/:id", firebaseAuth, Tips.updateTip);
router.delete("/tips/:id", firebaseAuth, Tips.deleteTip);

module.exports = router;
