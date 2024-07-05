import React, { useContext, useEffect, useState } from "react";
import { Spinner } from "react-bootstrap";
import MDButton from "components/MDButton";
import CloseIcon from "@mui/icons-material/Close";
import { green } from "@mui/material/colors";
import PropTypes from "prop-types";
import * as apiService from "../../api-service";
import { AuthContext } from "../../../context/AuthContext";
import {
  Box,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Icon,
  IconButton,
  TextField,
  Typography,
  styled,
} from "@mui/material";
import MDBox from "components/MDBox";
import DataTable from "examples/Tables/DataTable";
import { useLocation } from "react-router-dom";
import MDTypography from "components/MDTypography";

const BootstrapDialog = styled(Dialog)(({ theme }) => ({
  "& .MuiDialogContent-root": {
    padding: theme.spacing(1),
    width: "35em",
  },
  "& .MuiDialogActions-root": {
    padding: theme.spacing(1),
  },
}));
function BootstrapDialogTitle(props) {
  const { children, onClose, ...other } = props;
  return (
    <DialogTitle sx={{ m: 1.5, p: 2 }} {...other}>
      {children}
      {onClose ? (
        <IconButton
          aria-label="close"
          onClick={onClose}
          sx={{
            position: "absolute",
            right: 8,
            top: 8,
            color: (theme) => theme.palette.grey[500],
          }}
        >
          <CloseIcon />
        </IconButton>
      ) : null}
    </DialogTitle>
  );
}
BootstrapDialogTitle.propTypes = {
  children: PropTypes.node,
  onClose: PropTypes.func.isRequired,
};

function Orders() {
  const [orders, setOrders] = useState([]);
  const [selectedOrder, setSelectedOrder] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [deleteId, setDeleteId] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [orderModal, setOrderModal] = useState(false);

  const location = useLocation();
  const id = new URLSearchParams(location.search).get("id");

  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const orderModalOpen = () => setOrderModal(true);
  const orderModalClose = () => {
    setOrderModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getOrders({
            userIdToken,
            id,
          });
          setOrders(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching Orders: " + error.message);
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
        (order) => order.orderId !== deleteId
      );
      setOrders(updatedUserOrders);
    } catch (error) {
      console.error("Error deleting mobile user: ", error);
    }
  };

  //   const onUpdateOrder = async (e) => {
  //     e.preventDefault();
  //     if (!user || !user.getIdToken) {
  //       return;
  //     }
  //     const userIdToken = await user.getIdToken();
  //     try {
  //       await apiService.updatedOrder({
  //         userIdToken,
  //         id: selectedOrder.id,
  //         data: selectedOrder,
  //       });
  //       const updatedOrders = orders.map((order) =>
  //         order.id === selectedOrder.id ? selectedOrder : order
  //       );
  //       setOrders(updatedOrders);
  //       orderModalClose();
  //     } catch (error) {
  //       console.error("Error updating Order: ", error);
  //       setError2("Error updating Order: " + error.message);
  //     }
  //   };

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
      case "Paid":
        return "success";
      case "unPaid":
        return "error";
      default:
        return "";
    }
  };

  return (
    <div>
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

      {/* <BootstrapDialog
        onClose={orderModalClose}
        aria-labelledby="customized-dialog-title"
        open={orderModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={orderModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Edit Order
          </Typography>
        </BootstrapDialogTitle>
        <DialogContent dividers>
          <Box
            component="form"
            sx={{
              "& .MuiTextField-root": {
                m: 2,
                maxWidth: "100%",
                display: "flex",
                direction: "column",
                justifyContent: "center",
              },
            }}
            noValidate
            autoComplete="off"
          >
            <TextField
              label="Name"
              type="text"
              color="secondary"
              required
              value={selectedOrder.name}
              onChange={(e) =>
                setSelectedOrder({
                  ...selectedOrder,
                  name: e.target.value,
                })
              }
            />
            <TextField
              label="Phone"
              type="tel"
              color="secondary"
              required
              value={selectedOrder.phone}
              onChange={(e) =>
                setSelectedOrder({
                  ...selectedOrder,
                  phone: e.target.value,
                })
              }
            />
            <TextField
              label="Email"
              type="email"
              color="secondary"
              required
              value={selectedOrder.email}
              onChange={(e) =>
                setSelectedOrder({
                  ...selectedOrder,
                  email: e.target.value,
                })
              }
            />
            <TextField
              label="Address"
              type="text"
              color="secondary"
              required
              value={selectedOrder.address}
              onChange={(e) =>
                setSelectedOrder({
                  ...selectedOrder,
                  address: e.target.value,
                })
              }
            />
            <TextField
              label="ID Card Number"
              type="text"
              color="secondary"
              required
              value={selectedOrder.idCard}
              onChange={(e) =>
                setSelectedOrder({
                  ...selectedOrder,
                  idCard: e.target.value,
                })
              }
            />
            {error2 === "" ? null : (
              <Typography variant="body2" color="error">
                {error2}
              </Typography>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ justifyContent: "center" }}>
          {loading ? (
            <CircularProgress
              size={30}
              sx={{
                color: green[500],
              }}
            />
          ) : (
            <MDButton
              variant="contained"
              color="info"
              type="submit"
              onClick={onUpdateOrder}
            >
              Update
            </MDButton>
          )}
        </DialogActions>
      </BootstrapDialog> */}

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
        <DataTable
          pagination={{ variant: "gradient", color: "info" }}
          canSearch={true}
          table={{
            columns: [
              {
                Header: "Order ID",
                accessor: "orderId",
              },
              {
                Header: "Order Date",
                accessor: "orderDate",
              },
              {
                Header: "Area",
                accessor: "area",
              },
              {
                Header: "Customer Phone Number",
                accessor: "phoneNumber",
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
                Header: "Payment Status",
                accessor: "paymentStatus",
                Cell: ({ value }) => (
                  <MDTypography color={getStatusColor(value)} variant="body2">
                    {value}
                  </MDTypography>
                ),
              },
              {
                Header: "Cancel Reason",
                accessor: "cancelReason",
                show: orders.some((order) => order.status === 1),
              },
              {
                Header: "Actions",
                accessor: "action",
                align: "center",
              },
            ].filter(Boolean),
            rows: orders.map((order) => ({
              orderId: order.orderid,
              orderDate: formatDate(order.orderDate),
              area: order.area,
              phoneNumber: order.phoneNumber,
              items: order.recyclables
                .filter((item) => item.quantity > 0)
                .map((item) => `${item.quantity}kg ${item.item}`)
                .join(", "),
              totalPrice: order.totalPrice,
              totalWeight: order.totalWeight,
              status: getStatusLabel(order.status),
              paymentStatus: order.paymentStatus,
              cancelReason: order.cancelReason ? order.cancelReason : "-----",
              action: (
                <MDButton
                  variant="text"
                  color="error"
                  onClick={() => {
                    deleteAlertOpen();
                    setDeleteId(order.orderId);
                  }}
                >
                  <Icon>delete</Icon>
                </MDButton>
              ),
            })),
          }}
        />
      )}
    </div>
  );
}

export default Orders;
