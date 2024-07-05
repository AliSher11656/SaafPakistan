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

function Recyclables({ refreshRecyclables }) {
  const [recyclables, setRecyclables] = useState([]);
  const [selectedRecyclable, setSelectedRecyclable] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [deleteById, setDeleteById] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [RecyclableModal, setRecyclableModal] = useState(false);
  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const RecyclableModalOpen = () => setRecyclableModal(true);
  const RecyclableModalClose = () => {
    setRecyclableModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getRecyclablesData({
            userIdToken,
          });
          setRecyclables(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching recyclables: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user, refreshRecyclables]); // Add refreshRecyclables to the dependency array

  const handleDelete = async (id) => {
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.deleteRecyclable({ userIdToken, id });
      const updatedRecyclables = recyclables.filter(
        (Recyclable) => Recyclable.id !== id
      );
      setRecyclables(updatedRecyclables);
    } catch (error) {
      console.error("Error deleting recyclable: ", error);
    }
  };

  const onUpdateRecyclable = async (e) => {
    e.preventDefault();
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.updatedRecyclable({
        userIdToken,
        id: selectedRecyclable.id,
        data: selectedRecyclable,
      });
      const updatedRecyclables = recyclables.map((Recyclable) =>
        Recyclable.id === selectedRecyclable.id
          ? selectedRecyclable
          : Recyclable
      );
      setRecyclables(updatedRecyclables);
      RecyclableModalClose();
    } catch (error) {
      console.error("Error updating recyclable: ", error);
      setError2("Error updating recyclable: " + error.message);
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
        onClose={RecyclableModalClose}
        aria-labelledby="customized-dialog-title"
        open={RecyclableModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={RecyclableModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Edit recyclable
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
              label="Item"
              type="text"
              color="secondary"
              required
              value={selectedRecyclable.item}
              onChange={(e) =>
                setSelectedRecyclable({
                  ...selectedRecyclable,
                  item: e.target.value,
                })
              }
            />
            <TextField
              label="Individuals Price"
              type="number"
              color="secondary"
              required
              value={selectedRecyclable.price}
              onChange={(e) =>
                setSelectedRecyclable({
                  ...selectedRecyclable,
                  price: e.target.value,
                })
              }
            />
            <TextField
              label="Bussinesses Price"
              type="number"
              color="secondary"
              required
              value={selectedRecyclable.bizPrice}
              onChange={(e) =>
                setSelectedRecyclable({
                  ...selectedRecyclable,
                  bizPrice: e.target.value,
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
              onClick={onUpdateRecyclable}
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
              { Header: "Item", accessor: "item", width: "25%" },
              { Header: "Individuals Price", accessor: "price", width: "35%" },
              {
                Header: "Bussinesses Price",
                accessor: "bizPrice",
                width: "35%",
              },
              { Header: "Actions", accessor: "action", align: "center" },
            ],
            rows: recyclables.map((Recyclable) => ({
              item: Recyclable.item,
              price: Recyclable.price,
              bizPrice: Recyclable.bizPrice,
              action: (
                <MDBox display="flex" alignItems="center">
                  <MDBox mr={1}>
                    <MDButton
                      variant="text"
                      color="error"
                      onClick={() => {
                        deleteAlertOpen();
                        setDeleteById(Recyclable.id);
                      }}
                    >
                      <Icon>delete</Icon>
                    </MDButton>
                  </MDBox>
                  <MDButton
                    variant="text"
                    color={"dark"}
                    onClick={() => {
                      setSelectedRecyclable(Recyclable);
                      RecyclableModalOpen();
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

Recyclables.propTypes = {
  refreshRecyclables: PropTypes.bool.isRequired,
};

export default Recyclables;
