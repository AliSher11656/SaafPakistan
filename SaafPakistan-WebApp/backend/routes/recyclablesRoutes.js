const express = require("express");
const Recyclable = require("../controller/recyclables");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/recyclables", firebaseAuth, Recyclable.getRecyclables);
router.post("/recyclables", firebaseAuth, Recyclable.createRecyclable);
router.delete("/recyclables/:id", firebaseAuth, Recyclable.deleteRecyclable);
router.put("/recyclables/:id", firebaseAuth, Recyclable.updateRecyclable);

module.exports = router;
