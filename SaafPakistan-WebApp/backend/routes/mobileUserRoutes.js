const express = require("express");
const MobileUsers = require("../controller/mobileUsers");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get("/users", firebaseAuth, MobileUsers.getMobileUsers);

router.delete("/users/:id", firebaseAuth, MobileUsers.deleteMobileUser);

router.put("/users/:id", firebaseAuth, MobileUsers.updateMobileUser);

module.exports = router;
