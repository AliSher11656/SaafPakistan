import Dashboard from "layouts/dashboard";

import Signup from "layouts/authentication/users/Signup";

import DashboardIcon from "@mui/icons-material/Dashboard";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import TwoWheelerIcon from "@mui/icons-material/TwoWheeler";
import WarehouseIcon from "@mui/icons-material/Warehouse";
import PeopleIcon from "@mui/icons-material/People";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import RecyclingIcon from "@mui/icons-material/Recycling";
import ListAltIcon from "@mui/icons-material/ListAlt";
import TipsAndUpdatesIcon from "@mui/icons-material/TipsAndUpdates";
import LeaderboardOutlinedIcon from "@mui/icons-material/LeaderboardOutlined";
import PaymentsIcon from "@mui/icons-material/Payments";

import * as React from "react";
import { Navigate } from "react-router-dom";
import { useContext } from "react";
import { AuthContext } from "context/AuthContext";
import Rider from "layouts/riders";
import WarehouseManager from "layouts/warehouseManager";
import MobileUser from "layouts/mobileUsers";
import RiderSignup from "layouts/authentication/users/RiderSignup";
import Area from "layouts/areas";
import Recyclable from "layouts/recyclables";
import UserOrders from "layouts/mobileUsers/orders/Orders";
import RiderOrders from "layouts/riders/Orders/Orders";
import Order from "layouts/orders";
import Tip from "layouts/tips";
import Leaderboard from "layouts/leaderboard";
import Payment from "layouts/payment";

const AdminAuthRoutes = ({ children }) => {
  const { role } = useContext(AuthContext);
  return role === "admin" ? children : <Navigate to="/login" />;
};
const WarehouseManagerAuthRoutes = ({ children }) => {
  const { role } = useContext(AuthContext);
  return role === "warehouseManager" ? children : <Navigate to="/login" />;
};

const routes = [
  {
    routeRole: "admin",
    type: "collapse",
    name: "Dashboard",
    key: "admin/dashboard",
    icon: <DashboardIcon />,
    route: "/admin/dashboard",
    component: (
      <AdminAuthRoutes>
        <Dashboard />
      </AdminAuthRoutes>
    ),
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Riders",
    key: "rider",
    icon: <TwoWheelerIcon />,
    route: "/rider",
    component: (
      <AdminAuthRoutes>
        <Rider />
      </AdminAuthRoutes>
    ),
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Warehouse Managers",
    key: "warehouseManager",
    icon: <WarehouseIcon />,
    route: "/warehouseManager",
    component: (
      <AdminAuthRoutes>
        <WarehouseManager></WarehouseManager>
      </AdminAuthRoutes>
    ),
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Users",
    key: "users",
    icon: <PeopleIcon />,
    route: "/users",
    component: <AdminAuthRoutes>{<MobileUser></MobileUser>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Areas",
    key: "areas",
    icon: <LocationOnIcon />,
    route: "/areas",
    component: <AdminAuthRoutes>{<Area></Area>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Recyclables",
    key: "recyclables",
    icon: <RecyclingIcon />,
    route: "/recyclables",
    component: <AdminAuthRoutes>{<Recyclable></Recyclable>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Orders",
    key: "orders",
    icon: <ListAltIcon />,
    route: "/orders",
    component: <AdminAuthRoutes>{<Order></Order>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Payment",
    key: "payment",
    icon: <PaymentsIcon />,
    route: "/payment",
    component: <AdminAuthRoutes>{<Payment></Payment>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Tips",
    key: "tips",
    icon: <TipsAndUpdatesIcon />,
    route: "/tips",
    component: <AdminAuthRoutes>{<Tip></Tip>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Leaderboard",
    key: "leaderboard",
    icon: <LeaderboardOutlinedIcon />,
    route: "/leaderboard",
    component: <AdminAuthRoutes>{<Leaderboard></Leaderboard>}</AdminAuthRoutes>,
  },
  {
    routeRole: "admin",
    type: "collapse",
    name: "Register",
    icon: <PersonAddIcon />,
    route: "/signup",
    component: (
      <AdminAuthRoutes>
        <Signup />
      </AdminAuthRoutes>
    ),
  },

  ////////////////////Warehouse Manager routes/////////////////////////////////////////

  {
    routeRole: "warehouseManager",
    type: "collapse",
    name: "Dashboard",
    key: "warehouseManager/dashboard",
    icon: <DashboardIcon />,
    route: "/warehouseManager/dashboard",
    component: (
      <WarehouseManagerAuthRoutes>
        <Dashboard />
      </WarehouseManagerAuthRoutes>
    ),
  },
  {
    routeRole: "warehouseManager",
    type: "collapse",
    name: "Riders",
    key: "warehouseManager/rider",
    icon: <TwoWheelerIcon />,
    route: "/warehouseManager/rider",
    component: (
      <WarehouseManagerAuthRoutes>
        <Rider />
      </WarehouseManagerAuthRoutes>
    ),
  },
  // {
  //   routeRole: "warehouseManager",
  //   type: "collapse",
  //   name: "Orders",
  //   key: "orders",
  //   icon: <ListAltIcon />,
  //   route: "/orders",
  //   component: (
  //     <WarehouseManagerAuthRoutes>
  //       <Order></Order>
  //     </WarehouseManagerAuthRoutes>
  //   ),
  // },
  {
    routeRole: "warehouseManager",
    type: "collapse",
    name: "Add Rider",
    key: "warehouseManager/Add Rider",
    icon: <PersonAddIcon />,
    route: "/warehouseManager/addRider",
    component: (
      <WarehouseManagerAuthRoutes>
        <RiderSignup></RiderSignup>
      </WarehouseManagerAuthRoutes>
    ),
  },
];

const authRoutes = [
  {
    routeRole: "admin",
    type: "authRoutes",
    route: "users/:id",
    component: (
      <AdminAuthRoutes>
        <UserOrders></UserOrders>
      </AdminAuthRoutes>
    ),
  },
  {
    routeRole: "admin",
    type: "authRoutes",
    route: "rider/:id",
    component: (
      <AdminAuthRoutes>
        <RiderOrders></RiderOrders>
      </AdminAuthRoutes>
    ),
  },
  {
    routeRole: "admin",
    type: "authRoutes",
    route: "orders/:id",
    component: <AdminAuthRoutes></AdminAuthRoutes>,
  },
  {
    routeRole: "warehouseManager",
    type: "authRoutes",
    route: "rider/:id",
    component: (
      <WarehouseManagerAuthRoutes>
        <RiderOrders></RiderOrders>
      </WarehouseManagerAuthRoutes>
    ),
  },
  {
    routeRole: "warehouseManager",
    type: "authRoutes",
    route: "orders/:id",
    component: <WarehouseManagerAuthRoutes></WarehouseManagerAuthRoutes>,
  },
];
export default routes;
export { authRoutes };
