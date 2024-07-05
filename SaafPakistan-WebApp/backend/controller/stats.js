const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getData = async (req, res, next) => {
  try {
    const orderCollectionRef = firestore.collection("orders");
    const querySnapshot = await orderCollectionRef.get();

    const paymentCollectionRef = firestore.collection("payments");
    const paymentQuerySnapshot = await paymentCollectionRef.get();

    const ordersData = [];
    const year = new Date().getFullYear();

    const usersSignedData = {
      labels: [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ],
      datasets: { label: "User Signups", data: [] },
    };

    const paymentData = {
      labels: [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ],
      datasets: { label: "Paid Amount", data: [] },
    };

    // Iterate over each month for payment stats
    for (let month = 0; month < 12; month++) {
      const startOfMonth = new Date(year, month, 1);
      const endOfMonth = new Date(year, month + 1, 0);

      // Filter payments made during the current month
      const paymentsThisMonth = paymentQuerySnapshot.docs.filter((payment) => {
        const paymentDate = new Date(payment.data().createdAt);
        return paymentDate >= startOfMonth && paymentDate <= endOfMonth;
      });

      // Calculate total amount paid during the current month
      const totalAmount = paymentsThisMonth.reduce((total, payment) => {
        const amount = parseFloat(payment.data().amount);
        return total + amount;
      }, 0);

      // Push total amount paid during the current month to datasets
      paymentData.datasets.data.push(totalAmount);
    }

    // Fetch all users
    const listUsersResult = await admin.auth().listUsers();
    const users = listUsersResult.users;

    // Iterate over each month
    for (let month = 0; month < 12; month++) {
      const startOfMonth = new Date(year, month, 1);
      const endOfMonth = new Date(year, month + 1, 0);

      // Filter users who signed up during the current month
      const usersSignedUpThisMonth = users.filter((user) => {
        const creationDate = new Date(user.metadata.creationTime);
        return creationDate >= startOfMonth && creationDate <= endOfMonth;
      });

      // Push count of users created during the current month to datasets
      usersSignedData.datasets.data.push(usersSignedUpThisMonth.length);
    }

    querySnapshot.forEach((docSnap) => {
      const order = docSnap.data();
      const orderId = docSnap.id;

      // Check if items is an array before attempting to iterate over it
      const recyclables = Array.isArray(order.recyclables)
        ? order.recyclables.map((item) => ({
            item: item.item,
            price: item.price,
            quantity: item.quantity,
          }))
        : [];

      const orderObject = {
        orderId: orderId,
        address: order.address,
        area: order.area,
        customer: order.customer,
        orderDate: order.orderDate.toDate(), // Convert Firebase Timestamp to Date object
        phoneNumber: order.phoneNumber,
        recyclables: recyclables,
        status: order.status,
        totalPrice: order.totalPrice,
        totalWeight: order.totalWeight,
      };

      ordersData.push(orderObject);
    });

    res.status(200).json({
      orders: ordersData,
      usersSigned: usersSignedData,
      paymentStats: paymentData,
    });
  } catch (error) {
    console.error("Error fetching data:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
