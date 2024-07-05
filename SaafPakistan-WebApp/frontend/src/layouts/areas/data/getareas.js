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
  CircularProgress,
} from "@mui/material";
import MDBox from "components/MDBox";
import { Icon } from "@mui/material";
import PropTypes from "prop-types";
import CloseIcon from "@mui/icons-material/Close";
import { Box } from "@mui/system";
import DataTable from "examples/Tables/DataTable";
import { green } from "@mui/material/colors";

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

function Areas({ refreshAreas }) {
  const [areas, setAreas] = useState([]);
  const [selectedArea, setSelectedArea] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [deleteById, setDeleteById] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [AreaModal, setAreaModal] = useState(false);
  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const AreaModalOpen = () => setAreaModal(true);
  const AreaModalClose = () => {
    setAreaModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getareasData({
            userIdToken,
          });
          setAreas(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching areas: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user, refreshAreas]); // Add refreshAreas to the dependency array

  const handleDelete = async (id) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.deleteArea({ userIdToken, id });
      const updatedAreas = areas.filter((Area) => Area.id !== id);
      setAreas(updatedAreas);
    } catch (error) {
      console.error("Error deleting area: ", error);
    }
  };

  const onUpdateArea = async (e) => {
    e.preventDefault();
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.updatedArea({
        userIdToken,
        id: selectedArea.id,
        data: selectedArea,
      });
      const updatedAreas = areas.map((Area) =>
        Area.id === selectedArea.id ? selectedArea : Area
      );
      setAreas(updatedAreas);
      AreaModalClose();
    } catch (error) {
      console.error("Error updating area: ", error);
      setError2("Error updating area: " + error.message);
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
        onClose={AreaModalClose}
        aria-labelledby="customized-dialog-title"
        open={AreaModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={AreaModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Edit area
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
              label="ID"
              type="text"
              color="secondary"
              required
              disabled
              value={selectedArea.id}
            />
            <TextField
              label="Location"
              type="text"
              color="secondary"
              required
              value={selectedArea.location}
              onChange={(e) =>
                setSelectedArea({
                  ...selectedArea,
                  location: e.target.value,
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
              onClick={onUpdateArea}
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
              { Header: "ID", accessor: "id", width: "25%" },
              { Header: "Location", accessor: "location", width: "35%" },

              { Header: "Actions", accessor: "action", align: "center" },
            ],
            rows: areas.map((Area) => ({
              id: Area.id,
              location: Area.location,
              action: (
                <MDBox display="flex" alignItems="center">
                  <MDBox mr={1}>
                    <MDButton
                      variant="text"
                      color="error"
                      onClick={() => {
                        deleteAlertOpen();
                        setDeleteById(Area.id);
                      }}
                    >
                      <Icon>delete</Icon>
                    </MDButton>
                  </MDBox>
                  <MDButton
                    variant="text"
                    color={"dark"}
                    onClick={() => {
                      setSelectedArea(Area);
                      AreaModalOpen();
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

Areas.propTypes = {
  refreshAreas: PropTypes.bool.isRequired,
};

export default Areas;
