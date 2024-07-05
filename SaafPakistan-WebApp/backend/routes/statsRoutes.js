const express = require("express");
const Stats = require("../controller/stats");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get(
  "/admin/dashboard",
  // firebaseAuth,
  Stats.getData
);

module.exports = router;
