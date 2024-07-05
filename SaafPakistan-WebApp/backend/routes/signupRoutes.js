const express = require("express");
const Signup = require("../controller/signup");
const Area = require("../controller/areas");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.post("/signup", firebaseAuth, Signup.signup);
router.get("/signup", firebaseAuth, Area.getAreas);

module.exports = router;
