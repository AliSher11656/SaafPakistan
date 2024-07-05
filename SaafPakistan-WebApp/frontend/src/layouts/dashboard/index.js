import * as React from "react";

import DashboardLayout from "examples/LayoutContainers/DashboardLayout";
import DashboardNavbar from "examples/Navbars/DashboardNavbar";
import * as apiService from "../api-service";
import { AuthContext } from "../../context/AuthContext";
import { Grid } from "@mui/material";
import MDBox from "components/MDBox";
import DefaultInfoCard from "examples/Cards/InfoCards/DefaultInfoCard";
import ReportsLineChart from "examples/Charts/LineCharts/ReportsLineChart";
import { Link } from "react-router-dom";
import ReportsBarChart from "examples/Charts/BarCharts/ReportsBarChart";
import MDTypography from "components/MDTypography";
import VerticalBarChart from "examples/Charts/BarCharts/VerticalBarChart";

function Dashboard() {
  const [numberOfOrders, setNumberOfOrders] = React.useState(0);
  const { user } = React.useContext(AuthContext);
  const date = new Date();

  const [orderStatusCounts, setOrderStatusCounts] = React.useState({
    pending: 0,
    completed: 0,
    cancelled: 0,
  });
  const [usersSignedData, setUsersSignedData] = React.useState({
    labels: [],
    datasets: { label: "", data: [] },
  });
  const [recyclablesChartData, setRecyclablesChartData] = React.useState({
    labels: [],
    datasets: { label: "", data: [] },
  });

  const [paymentData, setPaymentData] = React.useState({
    labels: [],
    datasets: { label: "", data: [] },
  });

  const totalAmountPaid = paymentData.datasets.data.reduce(
    (total, amount) => total + amount,
    0
  );
  const paymentChartData = {
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
    datasets: [
      {
        label: "Paid Amount",
        color: "success",
        data: paymentData.datasets.data,
      },
    ],
  };

  function getLastThirtyDaysStartDate() {
    const today = new Date();
    const lastThirtyDays = new Date(today);
    lastThirtyDays.setDate(today.getDate() - 29);
    return lastThirtyDays.toLocaleDateString();
  }

  function getLastThirtyDaysEndDate() {
    return new Date().toLocaleDateString();
  }

  React.useEffect(() => {
    const fetchOrders = async () => {
      if (!user || !user.getIdToken) {
        return;
      }
      const userIdToken = await user.getIdToken();
      try {
        const Data = await apiService.getStats(userIdToken);
        const orders = Data.orders;
        const filteredOrders = Data.orders.filter((order) => {
          const last30days = new Date();
          last30days.setDate(last30days.getDate() - 29);

          return new Date(order.orderDate) >= last30days;
        });

        const usersSignedData = Data.usersSigned;
        setUsersSignedData(usersSignedData);

        const numberOfOrders = orders.length;
        setNumberOfOrders(numberOfOrders);

        const paymentData = Data.paymentStats;
        setPaymentData(paymentData);

        const totalAmountPaid = paymentData.datasets.data.reduce(
          (total, amount) => total + amount,
          0
        );

        const counts = orders.reduce(
          (acc, order) => {
            if (order.status === 0) acc.pending++;
            else if (order.status === 1) acc.cancelled++;
            else if (order.status === 2) acc.completed++;
            else if (order.status === 3) acc.cancelled++;
            return acc;
          },
          { pending: 0, completed: 0, cancelled: 0 }
        );
        setOrderStatusCounts(counts);
        const recyclablesChart = filteredOrders.reduce(
          (acc, order) => {
            order.recyclables.forEach((item) => {
              const { item: itemName, quantity } = item;
              const index = acc.labels.indexOf(itemName);

              if (index !== -1) {
                acc.datasets.data[index] += quantity;
              } else {
                acc.labels.push(itemName);
                acc.datasets.data.push(quantity);
              }
            });
            return acc;
          },
          { labels: [], datasets: { label: "Total Quantity in Kg", data: [] } }
        );
        setRecyclablesChartData(recyclablesChart);
      } catch (error) {
        console.error("Error fetching orders:", error);
      }
    };

    fetchOrders();
  }, [user]);

  return (
    <DashboardLayout>
      <DashboardNavbar />
      <>
        <Grid container spacing={3}>
          <Grid item xs={12} md={6} lg={3}>
            <Link to={`/orders`}>
              <DefaultInfoCard
                icon="shopping_cart"
                title="Total Orders"
                description="Total number of orders placed"
                value={numberOfOrders}
              />
            </Link>
          </Grid>
          <Grid item xs={12} md={6} lg={3}>
            <MDBox mb={1.5}>
              <Link to={`/orders?id=${0}`}>
                <DefaultInfoCard
                  icon="pending"
                  title="Pending Orders"
                  description="Total number of pending pickups"
                  value={orderStatusCounts.pending}
                />
              </Link>
            </MDBox>
          </Grid>
          <Grid item xs={12} md={6} lg={3}>
            <MDBox mb={1.5}>
              <Link to={`/orders?id=${2}`}>
                <DefaultInfoCard
                  icon="check_circle"
                  title="Completed Orders"
                  description="Total number of pickups completed"
                  value={orderStatusCounts.completed}
                />
              </Link>
            </MDBox>
          </Grid>
          <Grid item xs={12} md={6} lg={3}>
            <MDBox mb={1.5}>
              <Link to={`/orders?id=${1}`}>
                <DefaultInfoCard
                  icon="cancel"
                  title="Cancelled Orders"
                  description="Total number of cancelled pickups"
                  value={orderStatusCounts.cancelled}
                />
              </Link>
            </MDBox>
          </Grid>
        </Grid>
        <MDBox mt={4.5}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6} lg={4}>
              <MDBox mb={3}>
                <ReportsLineChart
                  color="success"
                  title="Users Signed Up"
                  description={
                    <>
                      Total users signed up in{" "}
                      <strong>{date.getFullYear()}</strong>.{" "}
                    </>
                  }
                  date={date.toLocaleDateString()}
                  chart={usersSignedData}
                />
              </MDBox>
            </Grid>
            <Grid item xs={12} md={6} lg={4}>
              <MDBox mb={3}>
                <VerticalBarChart
                  icon={{ color: "success", component: "leaderboard" }}
                  title="Payment statistics by month"
                  description={
                    <>
                      Total amount paid to customers in the last 12 months.{" "}
                      <strong>Total = {totalAmountPaid} PKR</strong>
                    </>
                  }
                  chart={paymentChartData}
                />
              </MDBox>
            </Grid>

            <Grid item xs={12} md={6} lg={4}>
              <MDBox mb={3}>
                <ReportsBarChart
                  color="success"
                  title="Recyclable Items"
                  description={`Total recyclable items based on orders placed in the last 30 days.`}
                  date={`from ${getLastThirtyDaysStartDate()} to ${getLastThirtyDaysEndDate()}`}
                  chart={recyclablesChartData}
                />
              </MDBox>
            </Grid>
          </Grid>
        </MDBox>
      </>
    </DashboardLayout>
  );
}

export default Dashboard;
