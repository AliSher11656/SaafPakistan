const express = require("express");
const Login = require("../controller/login");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.post(
  "/login",
  //  firebaseAuth,
  Login.login
);

module.exports = router;
