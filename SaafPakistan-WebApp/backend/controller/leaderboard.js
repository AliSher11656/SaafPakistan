const admin = require("firebase-admin");
const firestore = admin.firestore();

module.exports.getLeaderboard = async (req, res, next) => {
  try {
    const leaderboardCollectionRef = firestore.collection("leaderboards");

    const type = req.query.type || "Personal";

    const querySnapshot = await leaderboardCollectionRef
      .where("accountType", "==", type)
      .orderBy("points", "desc")
      .get();

    let rank = 1;
    const leaderboardData = [];
    querySnapshot.forEach((docSnap) => {
      const leaderboard = docSnap.data();
      const leaderboardId = docSnap.id;

      const leaderboardObject = {
        id: leaderboardId,
        uid: leaderboard.uid,
        cus: leaderboard.cus,
        points: leaderboard.points,
        accountType: leaderboard.accountType,
        rank: rank++,
      };

      leaderboardData.push(leaderboardObject);
    });

    res.status(200).json(leaderboardData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
