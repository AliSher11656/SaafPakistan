import * as apiService from "../../api-service";
import { useLocation } from "react-router-dom";
import DataTable from "examples/Tables/DataTable";
import { Spinner } from "react-bootstrap";
import { AuthContext } from "context/AuthContext";
import MDTypography from "components/MDTypography";
import { useContext, useEffect, useState } from "react";
import MDButton from "components/MDButton";
import {
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Icon,
} from "@mui/material";

function GetMobileUsersOrders() {
  const [orders, setOrders] = useState([]);
  const { user } = useContext(AuthContext);
  const location = useLocation();
  const id = new URLSearchParams(location.search).get("id");
  const name = new URLSearchParams(location.search).get("name");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [deleteId, setDeleteId] = useState(null);

  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);

  useEffect(() => {
    if (user && user.getIdToken && id) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getUserOrders({
            userIdToken,
            id,
          });
          setOrders(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching mobile users: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user, id]);

  const handleDelete = async (deleteId) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.deleteOrder({ userIdToken, id, deleteId });
      const updatedUserOrders = orders.filter(
        (mobileUser) => mobileUser.id !== deleteId
      );
      setOrders(updatedUserOrders);
    } catch (error) {
      console.error("Error deleting mobile user: ", error);
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 0:
        return "Pending";
      case 1:
        return "Cancelled";
      case 2:
        return "Completed";
      case 3:
        return "In Process";
      default:
        return "Unknown";
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toISOString().split("T")[0];
  };

  const getStatusColor = (status) => {
    switch (status) {
      case "Completed":
        return "success";
      case "Cancelled":
        return "error";
      case "Pending":
        return "warning";
      default:
        return "";
    }
  };

  return (
    <>
      <Dialog
        open={deleteAlert}
        onClose={deleteAlertClose}
        aria-labelledby="alert-dialog-title"
        aria-describedby="alert-dialog-description"
      >
        <DialogTitle id="alert-dialog-title">{"Alert"}</DialogTitle>
        <DialogContent>
          <DialogContentText id="alert-dialog-description">
            Are you sure you want to delete this?
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <MDButton
            variant="text"
            color={"dark"}
            onClick={() => {
              setDeleteId(null);
              deleteAlertClose();
            }}
          >
            Cancel
          </MDButton>
          <MDButton
            variant="text"
            color="error"
            sx={{ color: "error.main" }}
            onClick={() => {
              handleDelete(deleteId);
              deleteAlertClose();
            }}
          >
            Delete
          </MDButton>
        </DialogActions>
      </Dialog>
      {loading ? (
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "200px",
          }}
        >
          <Spinner
            animation="border"
            role="status"
            style={{ width: "100px", height: "100px" }}
          >
            <span className="visually-hidden">Loading...</span>
          </Spinner>
        </div>
      ) : error ? (
        <div>Error: {error}</div>
      ) : (
        <>
          <MDTypography
            variant="h5"
            fontWeight="medium"
            sx={{ textAlign: "center" }}
          >
            Orders placed by : {name}
          </MDTypography>
          <DataTable
            isSorted={true}
            canSearch={true}
            pagination={{ variant: "gradient", color: "info" }}
            table={{
              columns: [
                {
                  Header: "Order ID",
                  accessor: "orderId",
                  width: "10%",
                },
                {
                  Header: "Order Date",
                  accessor: "orderDate",
                  width: "12%",
                },
                {
                  Header: "Items",
                  accessor: "items",
                  width: "30%",
                },
                {
                  Header: "Total Price",
                  accessor: "totalPrice",
                  width: "10%",
                },
                {
                  Header: "Total Weight",
                  accessor: "totalWeight",
                  width: "10%",
                },
                {
                  Header: "Status",
                  accessor: "status",
                  width: "15%",
                  Cell: ({ value }) => (
                    <MDTypography color={getStatusColor(value)} variant="body2">
                      {value}
                    </MDTypography>
                  ),
                },
                {
                  Header: "Actions",
                  accessor: "action",
                  align: "center",
                  width: "5%",
                },
              ],
              rows: orders.map((order) => ({
                orderId: order.orderid,
                orderDate: formatDate(order.orderDate),
                items: order.recyclables
                  .filter((item) => item.quantity > 0)
                  .map((item) => `${item.quantity}kg ${item.item}`)
                  .join(", "),
                totalPrice: order.totalPrice,
                totalWeight: order.totalWeight,
                status: getStatusLabel(order.status),
                action: (
                  <MDButton
                    variant="text"
                    color="error"
                    onClick={() => {
                      deleteAlertOpen();
                      setDeleteId(order.id);
                    }}
                  >
                    <Icon>delete</Icon>
                  </MDButton>
                ),
              })),
            }}
          />
        </>
      )}
    </>
  );
}

export default GetMobileUsersOrders;
