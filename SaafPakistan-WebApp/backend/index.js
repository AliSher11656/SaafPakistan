require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const morgan = require("morgan");
const functions = require("firebase-functions");
const firebaseConfig = require("./firebase.config");
const { initializeApp } = require("firebase/app");
const admin = require("firebase-admin");
const serviceAccount = require("./service-account-key.json");
const multer = require("multer");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "gs://saafpakistan123.appspot.com",
});
initializeApp(firebaseConfig);

const { v4: uuidv4 } = require("uuid");
const storage = admin.storage().bucket();
const firestore = admin.firestore();

// const routesHandler = require("./routes/handler.js");

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());
app.use(morgan("dev"));

const upload = multer({ storage: multer.memoryStorage() });

// Route for handling file upload and creating payment
app.post("/payment", upload.single("file"), async (req, res) => {
  try {
    const orderDocid = req.headers["orderdocid"];
    const userId = req.headers["userid"];
    const method = req.headers["method"];
    const amount = req.headers["amount"];

    // Ensure all required fields are present
    if (!orderDocid || !userId || !method || !amount) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Extract uploaded file
    const file = req.file;

    // Upload file to Firebase Storage if it exists
    let fileUrl = null;
    if (file) {
      const fileName = `${uuidv4()}-${file.originalname}`;
      const fileRef = storage.file(fileName);

      // Save file to Firebase Storage
      await fileRef.save(file.buffer, {
        metadata: {
          contentType: file.mimetype,
        },
      });

      // Get public URL of uploaded file
      const url = await fileRef.getSignedUrl({
        action: "read",
        expires: "03-09-2491",
      });

      fileUrl = url[0];
    }

    // Create payment document in Firestore
    const paymentRef = firestore.collection("payments").doc();
    const payment = {
      id: paymentRef.id,
      orderDocid,
      userId,
      method,
      amount,
      status: "Paid",
      fileUrl: fileUrl,
      createdAt: new Date().toISOString(),
    };
    await paymentRef.set(payment);

    // Get order details and update order status
    const orderRef = firestore.collection("orders").doc(orderDocid);
    await orderRef.update({ paymentStatus: "Paid" });

    // Send response
    return res.status(200).json({ message: "Payment created successfully" });
  } catch (error) {
    console.error("Error handling file upload and payment creation:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
});

// const getUser = require("./routes/area");
// const WarehouseManagers = require("./routes/warehouseManagers");
// app.use("/", routesHandler);
const warehouseManagerRoutes = require("./routes/warehouseManagerRoutes");
const mobileUserRoutes = require("./routes/mobileUserRoutes");
const riderRoutes = require("./routes/riderRoutes");
const signupRoutes = require("./routes/signupRoutes");
const loginRoutes = require("./routes/loginRoutes");
const areaRoutes = require("./routes/areaRoutes");
const orderRoutes = require("./routes/orderRoutes");
const recyclableRoutes = require("./routes/recyclablesRoutes");
const statsRoutes = require("./routes/statsRoutes");
const tipsRoutes = require("./routes/tipsRoutes");
const leaderboardRoutes = require("./routes/leaderboardsRoutes");
const paymentRoutes = require("./routes/paymentRoutes");

const PORT = process.env.PORT || 4000; // backend routing port
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}.`);
});

app.use("/", warehouseManagerRoutes);
app.use("/", mobileUserRoutes);
app.use("/", riderRoutes);
app.use("/", signupRoutes);
app.use("/", loginRoutes);
app.use("/", areaRoutes);
app.use("/", orderRoutes);
app.use("/", recyclableRoutes);
app.use("/", statsRoutes);
app.use("/", tipsRoutes);
app.use("/", leaderboardRoutes);
app.use("/", paymentRoutes);

exports.api = functions.https.onRequest(app);
