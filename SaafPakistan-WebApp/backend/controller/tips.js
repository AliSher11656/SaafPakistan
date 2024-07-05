const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getTips = async (req, res, next) => {
  try {
    const tipsCollectionRef = firestore.collection("tips");
    const querySnapshot = await tipsCollectionRef.get();

    const tipsData = [];
    querySnapshot.forEach((docSnap) => {
      const tip = docSnap.data();
      const tipId = docSnap.id;

      const tipObject = {
        id: tipId,
        title: tip.title,
        description: tip.description,
      };

      tipsData.push(tipObject);
    });

    res.status(200).json(tipsData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports.createTip = async (req, res, next) => {
  try {
    const { title, description } = req.body;
    const tip = { title, description };

    const tipRef = await firestore.collection("tips").add(tip);
    const docSnap = await tipRef.get();

    res.status(201).json({ id: docSnap.id, ...docSnap.data() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports.updateTip = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description } = req.body;
    const tip = { title, description };

    const tipRef = firestore.collection("tips").doc(id);
    await tipRef.update(tip);

    res.status(200).json({ id, ...tip });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports.deleteTip = async (req, res, next) => {
  try {
    const { id } = req.params;

    await firestore.collection("tips").doc(id).delete();

    res.status(204).json();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
