import React, { useEffect, useState, useContext } from "react";
import { Spinner } from "react-bootstrap";
import MDButton from "components/MDButton";
import * as apiService from "../../api-service";
import { AuthContext } from "../../../context/AuthContext";
import {
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  styled,
  Typography,
  TextField,
  MenuItem,
} from "@mui/material";
import MDBox from "components/MDBox";
import { Icon } from "@mui/material";
import PropTypes from "prop-types";
import CloseIcon from "@mui/icons-material/Close";
import { Box } from "@mui/system";
import DataTable from "examples/Tables/DataTable";
import { Link } from "react-router-dom";

const BootstrapDialog = styled(Dialog)(({ theme }) => ({
  "& .MuiDialogContent-root": {
    padding: theme.spacing(2),
    width: "35em",
  },
  "& .MuiDialogActions-root": {
    padding: theme.spacing(1),
  },
}));

function BootstrapDialogTitle(props) {
  const { children, onClose, ...other } = props;
  return (
    <DialogTitle sx={{ m: 1, mb: 2 }} {...other}>
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

function Riders() {
  const [riders, setRiders] = useState([]);
  const [selectedRider, setSelectedRider] = useState({});
  const [userIdToken, setUserIdToken] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [dbareas, setdbAreas] = useState([]);
  const [deleteId, setDeleteId] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [ridersModal, setRidersModal] = useState(false);

  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const ridersModalOpen = () => setRidersModal(true);
  const ridersModalClose = () => {
    setRidersModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        setUserIdToken(userIdToken);
        try {
          const fetchedData = await apiService.getRidersData({
            userIdToken,
          });
          setRiders(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching riders: " + error.message);
          setLoading(false);
        }
      })();
    }
    fetchAreasData();
  }, [user, userIdToken]);

  const fetchAreasData = async () => {
    try {
      const fetchedData = await apiService.getAreasData({ userIdToken });
      setdbAreas(fetchedData);
    } catch (error) {
      console.error("Error fetching areas: ", error);
    }
  };

  const handleDelete = async (id) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.deleteRider({ userIdToken, id });
      const updatedRiders = riders.filter((rider) => rider.id !== id);
      setRiders(updatedRiders);
    } catch (error) {
      console.error("Error deleting rider: ", error);
    }
  };

  const onUpdateRider = async (e) => {
    e.preventDefault();
    if (!user || !user.getIdToken) {
      return;
    }
    dbareas.forEach((area) => {
      if (area.location === selectedRider.area) {
        selectedRider.area = area.id;
      }
    });

    const userIdToken = await user.getIdToken();
    try {
      await apiService.updateRider({
        userIdToken,
        id: selectedRider.id,
        data: selectedRider,
      });
      const updatedRiders = riders.map((rider) =>
        rider.id === selectedRider.id ? selectedRider : rider
      );
      setRiders(updatedRiders);
      dbareas.forEach((area) => {
        if (area.id === selectedRider.area) {
          selectedRider.area = area.location;
        }
      });
      ridersModalClose();
    } catch (error) {
      setError2("Error updating rider: " + error.message);
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

      <BootstrapDialog
        onClose={ridersModalClose}
        aria-labelledby="customized-dialog-title"
        open={ridersModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={ridersModalClose}
        >
          Update Rider
        </BootstrapDialogTitle>
        <DialogContent dividers>
          <Box
            component="form"
            sx={{
              "& .MuiTextField-root": { m: 1, width: "25ch" },
            }}
            noValidate
            autoComplete="off"
            onSubmit={onUpdateRider}
          >
            <TextField
              id="name"
              label="Name"
              defaultValue={selectedRider.name}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, name: e.target.value })
              }
            />
            <TextField
              id="email"
              label="Email"
              defaultValue={selectedRider.email}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, email: e.target.value })
              }
            />
            <TextField
              id="idCard"
              label="ID Card"
              defaultValue={selectedRider.idCard}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, idCard: e.target.value })
              }
            />

            <TextField
              id="area"
              label="Area"
              select
              sx={{ height: "2.8rem", m: 2 }}
              value={selectedRider.area}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, area: e.target.value })
              }
            >
              {dbareas.map((area) => (
                <MenuItem key={area.id} value={area.location}>
                  {area.location}
                </MenuItem>
              ))}
            </TextField>

            <TextField
              id="phone"
              label="Phone"
              defaultValue={selectedRider.phone}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, phone: e.target.value })
              }
            />
            <TextField
              id="vehicleNumber"
              label="Vehicle Number"
              defaultValue={selectedRider.vehicleNumber}
              onChange={(e) =>
                setSelectedRider({
                  ...selectedRider,
                  vehicleNumber: e.target.value,
                })
              }
            />
            <TextField
              id="address"
              label="Address"
              defaultValue={selectedRider.address}
              onChange={(e) =>
                setSelectedRider({ ...selectedRider, address: e.target.value })
              }
            />
            <Typography color="error">{error2}</Typography>
          </Box>
        </DialogContent>
        <DialogActions>
          <MDButton
            typr="submit"
            onClick={onUpdateRider}
            color="info"
            variant="contained"
          >
            Update
          </MDButton>
        </DialogActions>
      </BootstrapDialog>

      {loading ? (
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "200px", // Adjust height as needed
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
          canSearch={true}
          pagination={{ variant: "gradient", color: "info" }}
          table={{
            columns: [
              { Header: "Name", accessor: "name", width: "20%" },
              { Header: "Email", accessor: "email", width: "20%" },
              { Header: "ID Card", accessor: "idCard", width: "15%" },
              { Header: "Area", accessor: "area", width: "10%" },
              { Header: "Phone", accessor: "phone", width: "15%" },
              {
                Header: "Vehicle Number",
                accessor: "vehicleNumber",
                width: "10%",
              },
              { Header: "Address", accessor: "address", width: "20%" },
              { Header: "Actions", accessor: "action", align: "center" },
            ],
            rows: riders.map((rider) => ({
              name: rider.name,
              email: rider.email,
              idCard: rider.idCard,
              area: rider.area,
              phone: rider.phone,
              vehicleNumber: rider.vehicleNumber,
              address: rider.address,
              action: (
                <MDBox display="flex" alignItems="center" ml={-3}>
                  <Link
                    to={`/rider/${rider.id}?id=${rider.id}&name=${rider.name}`}
                  >
                    <MDButton variant="gradient" color="success" size="small">
                      Orders
                    </MDButton>
                  </Link>

                  <MDButton
                    variant="text"
                    color="error"
                    onClick={() => {
                      deleteAlertOpen();
                      setDeleteId(rider.id);
                    }}
                  >
                    <Icon>delete</Icon>
                  </MDButton>
                  <MDButton
                    variant="text"
                    color={"dark"}
                    onClick={() => {
                      setSelectedRider(rider);
                      fetchAreasData();
                      ridersModalOpen();
                    }}
                  >
                    <Icon>edit</Icon>
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

export default Riders;
