const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getRecyclables = async (req, res, next) => {
  try {
    const recyclablesCollectionRef = firestore.collection("recyclables");
    const querySnapshot = await recyclablesCollectionRef.get();

    const recyclablesData = [];
    querySnapshot.forEach((docSnap) => {
      const recyclable = docSnap.data();
      const recyclableId = docSnap.id;

      const recyclableObject = {
        id: recyclableId,
        item: recyclable.item,
        price: parseFloat(recyclable.price), // Convert price to a number
        bizPrice: parseFloat(recyclable.bizPrice),
      };

      recyclablesData.push(recyclableObject);
    });

    res.status(200).json(recyclablesData);
  } catch (error) {
    console.error("Error fetching recyclables: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.createRecyclable = async (req, res, next) => {
  try {
    const data = req.body;
    const recyclable = {
      item: data.item,
      price: parseFloat(data.price), // Convert price to a number
      bizPrice: parseFloat(data.bizPrice),
    };

    const recyclableDocRef = await firestore
      .collection("recyclables")
      .add(recyclable);

    res.status(201).json({ id: recyclableDocRef.id });
  } catch (error) {
    console.error("Error creating recyclable: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.deleteRecyclable = async (req, res, next) => {
  try {
    const id = req.params.id;

    await firestore.collection("recyclables").doc(id).delete();

    res.status(200).send("Recyclable deleted successfully");
  } catch (error) {
    console.error("Error deleting recyclable: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.updateRecyclable = async (req, res, next) => {
  try {
    const id = req.params.id;
    const data = req.body;

    await firestore
      .collection("recyclables")
      .doc(id)
      .update({
        item: data.item,
        price: parseFloat(data.price), // Convert price to a number
        bizPrice: parseFloat(data.bizPrice),
      });

    res.status(200).send("Recyclable updated successfully");
  } catch (error) {
    console.error("Error updating recyclable: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
