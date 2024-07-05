const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getAreas = async (req, res, next) => {
  try {
    const areaCollectionRef = firestore.collection("Areas");
    const querySnapshot = await areaCollectionRef.get();

    const areasData = [];

    querySnapshot.docs.map(async (docSnap) => {
      const area = docSnap.data();
      const areaId = docSnap.id;

      const areaObject = {
        id: areaId,
        location: area.location,
      };

      areasData.push(areaObject);
    });

    res.status(200).json(areasData);
  } catch (error) {
    console.error("Error fetching areas: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
module.exports.createArea = async (req, res, next) => {
  try {
    const data = req.body;
    // console.log("data == ", data);
    const areaRef = await firestore.collection("Areas").add({
      location: data.location,
    });

    res.status(200).json({ id: areaRef.id });
  } catch (error) {
    console.error("Error creating area: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.deleteArea = async (req, res, next) => {
  try {
    const id = req.params.id;

    await firestore.collection("Areas").doc(id).delete();

    res.status(200).send("Area deleted successfully");
  } catch (error) {
    console.error("Error deleting area: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.updateArea = async (req, res, next) => {
  try {
    const id = req.params.id;
    const data = req.body;

    await firestore.collection("Areas").doc(id).update({
      location: data.location,
    });

    res.status(200).send("Area updated successfully");
  } catch (error) {
    console.error("Error updating area: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
