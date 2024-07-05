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
import TouchAppIcon from "@mui/icons-material/TouchApp";

function GetRidersOrders() {
  const [orders, setOrders] = useState([]);
  const { user } = useContext(AuthContext);
  const location = useLocation();
  const id = new URLSearchParams(location.search).get("id");
  const riderName = new URLSearchParams(location.search).get("name");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [deleteId, setDeleteId] = useState(null);
  const [Verified, setVerified] = useState(false);
  const [verifyDialogOpen, setVerifyDialogOpen] = useState(false);

  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);

  useEffect(() => {
    if (user && user.getIdToken && id) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getRiderOrders({
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
      const updatedUserOrders = orders.filter((rider) => rider.id !== deleteId);
      setOrders(updatedUserOrders);
    } catch (error) {
      console.error("Error deleting mobile user: ", error);
    }
  };

  const updateRiderOrder = async (orderId, currentStatus) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      const data = {
        warehouseManagerOrderVerification: currentStatus ? 0 : 1, // Toggle the status
      };
      await apiService.updateRiderOrder({ userIdToken, id, orderId, data });

      const updatedOrders = orders.map((order) => {
        if (order.id === orderId) {
          return {
            ...order,
            warehouseManagerOrderVerification:
              data.warehouseManagerOrderVerification,
          };
        }
        return order;
      });
      setOrders(updatedOrders);

      // Update the Verified state for the specific order
      const newVerified = !currentStatus;
      setVerified(newVerified);
    } catch (error) {
      console.error("Error updating rider order: ", error);
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

      <Dialog
        open={verifyDialogOpen}
        onClose={() => setVerifyDialogOpen(false)}
        aria-labelledby="verify-dialog-title"
        aria-describedby="verify-dialog-description"
      >
        <DialogTitle id="verify-dialog-title">
          {"Verification Alert"}
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="verify-dialog-description">
            This order must be completed first to be verified.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <MDButton
            variant="outlined"
            color="primary"
            onClick={() => setVerifyDialogOpen(false)}
          >
            OK
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
            Orders Assigned to Rider: {riderName}
          </MDTypography>
          <DataTable
            isSorted={true}
            canSearch={true}
            pagination={{ variant: "gradient", color: "info" }}
            table={{
              columns: [
                {
                  Header: "Customer ID",
                  accessor: "customerId",
                },
                {
                  Header: "Order ID",
                  accessor: "orderId",
                },
                {
                  Header: "Order Date",
                  accessor: "orderDate",
                },
                {
                  Header: "Items",
                  accessor: "items",
                },
                {
                  Header: "Total Price",
                  accessor: "totalPrice",
                },
                {
                  Header: "Total Weight",
                  accessor: "totalWeight",
                },
                {
                  Header: "Order Status",
                  accessor: "status",
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
                },
              ],
              rows: orders.map((order) => ({
                customerId: order.customer,
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
                  <>
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
                    <MDButton
                      variant="outlined"
                      color={
                        order.warehouseManagerOrderVerification === 1
                          ? "success"
                          : "error"
                      }
                      onClick={() => {
                        if (order.status === 2) {
                          // Check if order status is "Completed"
                          setVerified(
                            order.warehouseManagerOrderVerification === 0
                              ? false
                              : true
                          );
                          updateRiderOrder(
                            order.id,
                            order.warehouseManagerOrderVerification
                          );
                        } else {
                          setVerifyDialogOpen(true); // Open dialog if order status is not "Completed"
                        }
                      }}
                    >
                      {order.warehouseManagerOrderVerification === 1
                        ? "Verified"
                        : "Unverified"}
                      <TouchAppIcon />
                    </MDButton>
                  </>
                ),
              })),
            }}
          />
        </>
      )}
    </>
  );
}

export default GetRidersOrders;
