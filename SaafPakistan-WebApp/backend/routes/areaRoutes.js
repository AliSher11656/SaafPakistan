const express = require("express");
const Area = require("../controller/areas");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/areas", firebaseAuth, Area.getAreas);
router.post("/areas", firebaseAuth, Area.createArea);
router.delete("/areas/:id", firebaseAuth, Area.deleteArea);
router.put("/areas/:id", firebaseAuth, Area.updateArea);

module.exports = router;
