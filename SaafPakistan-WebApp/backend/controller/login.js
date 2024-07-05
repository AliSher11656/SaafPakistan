// const firebase = require("firebase");
const admin = require("firebase-admin");
const bcrypt = require("bcrypt");
const firestore = admin.firestore();

module.exports.login = async (req, res, next) => {
  try {
    const data = req.body;
    const { email, password } = data;

    // Sign in the user
    const userCredential = await firebase
      .auth()
      .signInWithEmailAndPassword(email, password);
    const user = userCredential.user;

    // Retrieve user data from Firestore
    const userDoc = await firestore.collection("users").doc(user.uid).get();
    const userData = userDoc.data();

    // Compare the password
    const passwordMatch = await bcrypt.compare(password, userData.passwordHash);

    if (!passwordMatch) {
      throw new Error("Invalid email or password");
    }

    if (userData.role === "admin" || userData.role === "warehouseManager") {
      res.status(200).json({ role: userData.role });
    } else {
      res.status(200).json({ role: userData.role, area: userData.area.id });
    }
  } catch (error) {
    res.status(400).send(error.message);
  }
};
