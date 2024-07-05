const express = require("express");
const Leaderboard = require("../controller/leaderboard");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get(
  "/leaderboard",
  //  firebaseAuth,
  Leaderboard.getLeaderboard
);

router.get(
  "/leaderboard/organization",
  //  firebaseAuth,
  Leaderboard.getLeaderboard
);

module.exports = router;
