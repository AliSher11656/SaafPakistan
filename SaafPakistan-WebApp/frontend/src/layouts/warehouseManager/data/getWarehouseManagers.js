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

function WarehouseManagers() {
  const [warehouseManagers, setWarehouseManagers] = useState([]);
  const [selectedWarehouseManager, setSelectedWarehouseManager] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [deleteById, setDeleteById] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [warehouseManagerModal, setWarehouseManagerModal] = useState(false);
  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const warehouseManagerModalOpen = () => setWarehouseManagerModal(true);
  const warehouseManagerModalClose = () => {
    setWarehouseManagerModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getWarehouseManagerData({
            userIdToken,
          });
          // console.log("Fetched data:", fetchedData);
          setWarehouseManagers(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching warehouse managers: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user]);

  const handleDelete = async (id) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.deleteWarehouseManager({ userIdToken, id });
      const updatedWarehouseManagers = warehouseManagers.filter(
        (warehouseManager) => warehouseManager.id !== id
      );
      setWarehouseManagers(updatedWarehouseManagers);
    } catch (error) {
      console.error("Error deleting warehouse manager: ", error);
    }
  };

  const onUpdateWarehouseManager = async (e) => {
    e.preventDefault();
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.updatedWarehouseManager({
        userIdToken,
        id: selectedWarehouseManager.id,
        data: selectedWarehouseManager,
      });
      const updatedWarehouseManagers = warehouseManagers.map(
        (warehouseManager) =>
          warehouseManager.id === selectedWarehouseManager.id
            ? selectedWarehouseManager
            : warehouseManager
      );
      setWarehouseManagers(updatedWarehouseManagers);
      warehouseManagerModalClose();
    } catch (error) {
      console.error("Error updating warehouse manager: ", error);
      setError2("Error updating warehouse manager: " + error.message);
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
              setDeleteById(null);
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
              handleDelete(deleteById);
              deleteAlertClose();
            }}
          >
            Delete
          </MDButton>
        </DialogActions>
      </Dialog>

      <BootstrapDialog
        onClose={warehouseManagerModalClose}
        aria-labelledby="customized-dialog-title"
        open={warehouseManagerModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={warehouseManagerModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Edit Warehouse Manager
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
              value={selectedWarehouseManager.name}
              onChange={(e) =>
                setSelectedWarehouseManager({
                  ...selectedWarehouseManager,
                  name: e.target.value,
                })
              }
            />
            <TextField
              label="Phone"
              type="tel"
              color="secondary"
              required
              value={selectedWarehouseManager.phone}
              onChange={(e) =>
                setSelectedWarehouseManager({
                  ...selectedWarehouseManager,
                  phone: e.target.value,
                })
              }
            />
            <TextField
              label="Email"
              type="email"
              color="secondary"
              required
              value={selectedWarehouseManager.email}
              onChange={(e) =>
                setSelectedWarehouseManager({
                  ...selectedWarehouseManager,
                  email: e.target.value,
                })
              }
            />
            <TextField
              label="Address"
              type="text"
              color="secondary"
              required
              value={selectedWarehouseManager.address}
              onChange={(e) =>
                setSelectedWarehouseManager({
                  ...selectedWarehouseManager,
                  address: e.target.value,
                })
              }
            />
            <TextField
              label="ID Card Number"
              type="text"
              color="secondary"
              required
              value={selectedWarehouseManager.idCard}
              onChange={(e) =>
                setSelectedWarehouseManager({
                  ...selectedWarehouseManager,
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
              onClick={onUpdateWarehouseManager}
            >
              Update
            </MDButton>
          )}
        </DialogActions>
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
              { Header: "Name", accessor: "name", width: "25%" },
              { Header: "Phone", accessor: "phone", width: "15%" },
              { Header: "Email", accessor: "email", width: "20%" },
              { Header: "Address", accessor: "address", width: "25%" },
              { Header: "ID Card Number", accessor: "idCard", width: "15%" },
              { Header: "Actions", accessor: "action", align: "center" },
            ],
            rows: warehouseManagers.map((warehouseManager) => ({
              name: warehouseManager.name,
              phone: warehouseManager.phone,
              email: warehouseManager.email,
              address: warehouseManager.address,
              idCard: warehouseManager.idCard,
              action: (
                <MDBox display="flex" alignItems="center">
                  <MDBox mr={1}>
                    <MDButton
                      variant="text"
                      color="error"
                      onClick={() => {
                        deleteAlertOpen();
                        setDeleteById(warehouseManager.id);
                      }}
                    >
                      <Icon>delete</Icon>
                      {/* &nbsp;delete */}
                    </MDButton>
                  </MDBox>
                  <MDButton
                    variant="text"
                    color={"dark"}
                    onClick={() => {
                      setSelectedWarehouseManager(warehouseManager);
                      warehouseManagerModalOpen();
                    }}
                  >
                    <Icon>edit</Icon>
                    {/* &nbsp;edit */}
                  </MDButton>
                </MDBox>
              ),
            })),
          }}
        />
      )}
    </div>
  );
}

export default WarehouseManagers;
