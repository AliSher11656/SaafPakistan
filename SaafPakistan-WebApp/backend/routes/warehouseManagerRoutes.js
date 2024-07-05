const express = require("express");
const WarehouseManagers = require("../controller/warehouseManagers");
const firebaseAuth = require("../middleware/firebase-auth");

const router = express.Router();
router.get(
  "/warehouseManager",
  firebaseAuth,
  WarehouseManagers.getWarehouseManagers
);
router.delete(
  "/warehouseManager/:id",
  firebaseAuth,
  WarehouseManagers.deleteWarehouseManager
);

router.put(
  "/warehouseManager/:id",
  firebaseAuth,
  WarehouseManagers.updateWarehouseManager
);
module.exports = router;
