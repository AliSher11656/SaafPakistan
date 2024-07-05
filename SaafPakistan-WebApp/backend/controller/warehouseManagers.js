const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getWarehouseManagers = async (req, res, next) => {
  try {
    const warehouseManagerCollectionRef =
      firestore.collection("warehouseManager");
    const querySnapshot = await warehouseManagerCollectionRef.get(); // Use get() method to execute the query

    const warehouseManagersData = [];
    querySnapshot.forEach((docSnap) => {
      const warehouseManager = docSnap.data();
      const warehouseManagerId = docSnap.id;

      const warehouseManagerObject = {
        id: warehouseManagerId,
        name: warehouseManager.name,
        email: warehouseManager.email,
        idCard: warehouseManager.idCard,
        phone: warehouseManager.phone,
        address: warehouseManager.address,
      };

      warehouseManagersData.push(warehouseManagerObject);
    });

    res.status(200).json(warehouseManagersData);
  } catch (error) {
    console.error("Error fetching warehouse managers: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.deleteWarehouseManager = async (req, res, next) => {
  try {
    const id = req.params.id;

    await admin.auth().deleteUser(id);

    await firestore.collection("warehouseManager").doc(id).delete();
    await firestore.collection("users").doc(id).delete();

    res.status(200).send("Warehouse manager deleted successfully");
  } catch (error) {
    console.error("Error deleting warehouse manager: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.updateWarehouseManager = async (req, res, next) => {
  try {
    const id = req.params.id;
    const data = req.body;

    await admin.auth().updateUser(id, {
      email: data.email,
    });

    await firestore.collection("warehouseManager").doc(id).update({
      name: data.name,
      email: data.email,
      idCard: data.idCard,
      phone: data.phone,
      address: data.address,
    });

    await firestore.collection("users").doc(id).update({
      name: data.name,
      email: data.email,
      idCard: data.idCard,
      phone: data.phone,
      address: data.address,
    });

    res.status(200).send("Warehouse manager updated successfully");
  } catch (error) {
    console.error("Error updating warehouse manager: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
