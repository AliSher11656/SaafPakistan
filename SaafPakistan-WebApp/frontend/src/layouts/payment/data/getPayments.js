import React, { useContext, useEffect, useState } from "react";
import { Spinner } from "react-bootstrap";
import PropTypes from "prop-types";
import * as apiService from "../../api-service";
import { AuthContext } from "../../../context/AuthContext";
import DataTable from "examples/Tables/DataTable";
import { useLocation } from "react-router-dom";
import MDTypography from "components/MDTypography";
import MDButton from "components/MDButton";
import {
  Box,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  Icon,
  IconButton,
  InputAdornment,
  InputLabel,
  OutlinedInput,
  TextField,
  Typography,
} from "@mui/material";
import styled from "styled-components";
import MDBox from "components/MDBox";
import { green, red } from "@mui/material/colors";
import CloseIcon from "@mui/icons-material/Close";

const BootstrapDialog = styled(Dialog)(({ theme }) => ({
  "& .MuiDialogContent-root": {},
  "& .MuiDialogActions-root": {},
}));

function BootstrapDialogTitle(props) {
  const { children, onClose, ...other } = props;
  return (
    <DialogTitle sx={{ m: 0, p: 2 }} {...other}>
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

function Payments({ type }) {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [error2, setError2] = useState("");
  const { user } = useContext(AuthContext);
  const [paymentsSaleModal, setPaymentsModal] = useState(false);
  const [ssFile, setSSFile] = useState("");
  const [payment, setPayment] = useState(null); // Store the selected payment
  const [paymentType, setPaymentType] = useState(type);

  const location = useLocation();
  const id = new URLSearchParams(location.search).get("id");

  const paymentsSaleModalOpen = () => setPaymentsModal(true);
  const paymentsSaleModalClose = () => {
    setPaymentsModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getPayments({
            userIdToken,
            type: paymentType, // Pass the type to the API call
          });
          setPayments(fetchedData.ordersWithUserDetails);
          setLoading(false);
        } catch (error) {
          setError("Error fetching Payments: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user, paymentType]);

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

  const handleFileUpload = async (e) => {
    e.preventDefault();

    try {
      const userIdToken = await user.getIdToken();

      // Check if a payment is selected
      if (!payment) {
        setError2("No payment selected.");
        return;
      }

      // Check if a file is selected
      if (!ssFile) {
        setError2("No file selected.");
        return;
      }

      const data = {
        userId: payment.customer,
        method: payment.userDetails.paymentMethod,
        amount: payment.totalPrice,
        orderDocid: payment.orderDocid,
      };

      const uploadResult = await apiService.uploadPaymentProof({
        userIdToken,
        data,
        file: ssFile,
      });

      if (uploadResult) {
        // Remove the payment from the payments array
        const updatedPayments = payments.filter(
          (p) => p.orderDocid !== payment.orderDocid
        );
        setPayments(updatedPayments);
        paymentsSaleModalClose();
      }
    } catch (error) {
      console.error("Error uploading payment proof:", error);
      setError2("Error uploading payment proof: " + error.message);
    }
  };

  return (
    <div>
      <BootstrapDialog
        onClose={paymentsSaleModalClose}
        aria-labelledby="customized-dialog-title"
        open={paymentsSaleModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={paymentsSaleModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Add Payment Proof
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
            <Box sx={{ maxWidth: "100%", m: 2 }}>
              <FormControl fullWidth>
                <InputLabel htmlFor="outlined-adornment-amount">
                  Payment Proof
                </InputLabel>
                <OutlinedInput
                  sx={{ height: "2.8rem" }}
                  id="outlined-adornment-amount"
                  startAdornment={
                    <>
                      <InputAdornment position="start">
                        <input
                          multiple
                          type="file"
                          onChange={(e) => setSSFile(e.target.files[0])}
                        />
                      </InputAdornment>
                    </>
                  }
                  label="SS"
                />
              </FormControl>
            </Box>
            {error2 === "" ? null : (
              <MDBox mb={2} p={1}>
                <TextField
                  error
                  id="standard-error"
                  label="Error"
                  InputProps={{
                    readOnly: true,
                    sx: {
                      "& input": {
                        color: "red",
                      },
                    },
                  }}
                  value={error2}
                  variant="standard"
                />
              </MDBox>
            )}
            <MDBox
              mt={1}
              p={1}
              sx={{
                display: "flex",
                direction: "row",
                justifyContent: "center",
              }}
            >
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
                  onClick={handleFileUpload}
                  disabled={payment && payment.paymentStatus === "Paid"} // Disable button if payment status is Paid
                >
                  Save
                </MDButton>
              )}
            </MDBox>
          </Box>
        </DialogContent>
        <DialogActions></DialogActions>
      </BootstrapDialog>

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
                Header: "Customer ID",
                accessor: "customer",
              },
              {
                Header: "Order ID",
                accessor: "orderid",
              },
              {
                Header: "Customer Name",
                accessor: "userDetails.name",
              },
              {
                Header: "Total Price",
                accessor: "totalPrice",
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
                Header: "Payment Number",
                accessor: "paymentNumber",
              },
              {
                Header: "Payment Method",
                accessor: "paymentMethod",
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
                Header: "Payment Date",
                accessor: "paymentDate",
              },
              {
                Header: "Proof Image",
                accessor: "proofImage",
              },
              {
                Header: "Payment Proof",
                accessor: "paymentProof",
              },
            ],
            rows: payments.map((payment, index) => ({
              id: index,
              customer: payment.customer,
              orderid: payment.orderid,
              userDetails: payment.userDetails,
              totalPrice: payment.totalPrice,
              status: getStatusLabel(payment.status),
              paymentNumber: payment.userDetails.paymentNumber,
              paymentMethod: payment.userDetails.paymentMethod,
              paymentStatus: payment.paymentStatus,
              paymentDate:
                payment.paymentStatus === "Paid"
                  ? new Date(
                      payment.paymentDetails[0].createdAt
                    ).toLocaleDateString()
                  : "-----",
              proofImage:
                payment.paymentStatus === "Paid" ? (
                  <a
                    href={payment.paymentDetails[0].fileUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    View Proof
                  </a>
                ) : (
                  "-----"
                ),
              paymentProof: (
                <MDButton
                  variant="gradient"
                  color="info"
                  onClick={() => {
                    setPayment(payment); // Store the payment in state
                    paymentsSaleModalOpen(); // Open the modal
                  }}
                  disabled={payment.paymentStatus === "Paid"} // Disable button if payment status is Paid
                >
                  <Icon sx={{ fontWeight: "bold" }}>add</Icon>
                  &nbsp;Add Proof
                </MDButton>
              ),
            })),
          }}
        />
      )}
    </div>
  );
}

export default Payments;
