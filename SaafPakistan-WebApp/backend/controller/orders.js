const admin = require("firebase-admin");
const { getRider } = require("./riders");
const firestore = admin.firestore();

module.exports.getOrders = async (req, res, next) => {
  try {
    const statusId = req.params.id === "null" ? undefined : req.params.id;

    const orderCollectionRef = firestore.collection("orders");
    const querySnapshot = await orderCollectionRef.get();

    const ordersData = [];

    querySnapshot.forEach((docSnap) => {
      const order = docSnap.data();
      const orderId = docSnap.id;

      const recyclables = Array.isArray(order.recyclables)
        ? order.recyclables.map((item) => ({
            item: item.item,
            price: item.price,
            quantity: item.quantity,
          }))
        : [];
      const paymentStatus = order.paymentStatus
        ? order.paymentStatus
        : "unPaid";

      const orderObject = {
        orderId: orderId,
        orderid: order.orderid,
        address: order.address,
        area: order.area,
        customer: order.customer,
        orderDate: order.orderDate.toDate(),
        phoneNumber: order.phoneNumber,
        recyclables: recyclables,
        status: order.status,
        totalPrice: order.totalPrice,
        totalWeight: order.totalWeight,
        paymentStatus: paymentStatus,
      };

      if (statusId === undefined || statusId === order.status.toString()) {
        if (order.status === 1 && order.cancelReason) {
          orderObject.cancelReason = order.cancelReason;
        }
        ordersData.push(orderObject);
      }
    });

    res.status(200).json(ordersData);
  } catch (error) {
    console.error("Error fetching orders: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.getUserOrders = async (req, res, next) => {
  try {
    const userId = req.params.id;

    const orderCollectionRef = firestore.collection("orders");
    const querySnapshot = await orderCollectionRef
      .where("customer", "==", userId)
      .get();

    const ordersData = [];

    querySnapshot.forEach((docSnap) => {
      const order = docSnap.data();
      const orderId = docSnap.id;

      const recyclables = Array.isArray(order.recyclables)
        ? order.recyclables.map((item) => ({
            item: item.item,
            price: item.price,
            quantity: item.quantity,
          }))
        : [];

      const orderObject = {
        orderId: orderId,
        orderid: order.orderid,
        address: order.address,
        area: order.area,
        customer: order.customer,
        orderDate: order.orderDate.toDate(),
        phoneNumber: order.phoneNumber,
        recyclables: recyclables,
        status: order.status,
        totalPrice: order.totalPrice,
        totalWeight: order.totalWeight,
      };

      ordersData.push(orderObject);
    });

    res.status(200).json(ordersData);
  } catch (error) {
    console.error("Error fetching orders: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.getRiderOrders = async (req, res, next) => {
  try {
    const riderId = req.params.id;

    // Retrieve rider data
    const riderDoc = await firestore.collection("rider").doc(riderId).get();
    const rider = riderDoc.data();

    if (!rider) {
      res.status(404).json({ error: "Rider not found" });
      return;
    }

    const areaRef = rider.area;
    let area = null;

    if (areaRef) {
      const areaDoc = await firestore.doc(areaRef.path).get();
      area = areaDoc.data();
    }

    const riderData = {
      id: riderId,
      name: rider.name,
      email: rider.email,
      idCard: rider.idCard,
      area: area ? area.location : "",
      phone: rider.phone,
      vehicleNumber: rider.vehicleNumber,
      address: rider.address,
    };

    // Fetch orders based on the rider's area
    const orderCollectionRef = firestore.collection("orders");
    const querySnapshot = await orderCollectionRef
      .where("area", "==", riderData.area)
      .get();

    const ordersData = [];

    querySnapshot.forEach((docSnap) => {
      const order = docSnap.data();
      const orderId = docSnap.id;

      const recyclables = Array.isArray(order.recyclables)
        ? order.recyclables.map((item) => ({
            item: item.item,
            price: item.price,
            quantity: item.quantity,
          }))
        : [];

      const warehouseManagerOrderVerification =
        order.warehouseManagerOrderVerification !== undefined
          ? order.warehouseManagerOrderVerification
          : 0;

      const orderObject = {
        id: orderId,
        orderid: order.orderid,
        address: order.address,
        area: order.area,
        customer: order.customer,
        orderDate: order.orderDate.toDate(),
        phoneNumber: order.phoneNumber,
        recyclables: recyclables,
        status: order.status,
        totalPrice: order.totalPrice,
        totalWeight: order.totalWeight,
        warehouseManagerOrderVerification: warehouseManagerOrderVerification,
      };
      if (order.status === 2 && order.cancelReason) {
        orderObject.cancelReason = order.cancelReason;
      }
      ordersData.push(orderObject);
    });

    res.status(200).json(ordersData);
  } catch (error) {
    console.error("Error fetching orders: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.deleteOrder = async (req, res, next) => {
  try {
    const orderId = req.params.deleteId;

    await firestore.collection("orders").doc(orderId).delete();

    res.status(200).json({ message: "Order deleted successfully" });
  } catch (error) {
    console.error("Error deleting order: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports.updateRiderOrder = async (req, res, next) => {
  try {
    const orderId = req.params.orderId;
    const riderId = req.params.id;
    const data = req.body;

    await firestore.collection("orders").doc(orderId).update(data);

    res.status(200).json({ message: "Order updated successfully" });
  } catch (error) {
    console.error("Error updating order: ", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
