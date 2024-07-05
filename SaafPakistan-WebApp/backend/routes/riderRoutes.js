const express = require("express");
const Rider = require("../controller/riders");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/rider", firebaseAuth, Rider.getRiders);
router.delete("/rider/:id", firebaseAuth, Rider.deleteRider);
router.put("/rider/:id", firebaseAuth, Rider.updateRider);

module.exports = router;
