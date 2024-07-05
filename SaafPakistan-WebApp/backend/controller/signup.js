const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.signup = async (req, res, next) => {
  try {
    const data = req.body;
    const dbname = data.role;
    // console.log(dbname);
    // console.log(data);
    if (dbname === "rider") {
      const areaDocRef = firestore.collection("Areas").doc(data.area);
      data.area = areaDocRef;
      // console.log("areaDocRef == ", areaDocRef);

      await firestore.collection(dbname).doc(data.uid).set(data);

      res.status(200).send("Rider created successfully");
    } else if (dbname === "admin" || dbname === "warehouseManager") {
      await firestore.collection(dbname).doc(data.uid).set(data);
      await firestore.collection("users").doc(data.uid).set(data);

      res.status(200).send("User Added successfully");
    } else {
      res.status(400).send("Invalid role");
      return;
    }
  } catch (error) {
    res.status(400).send(error.message);
  }
};
