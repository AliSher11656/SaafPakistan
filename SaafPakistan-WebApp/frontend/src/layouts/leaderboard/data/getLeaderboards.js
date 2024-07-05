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

function Leaderboards({ type }) {
  const [leaderboards, setLeaderboards] = useState([]);
  const [selectedLeaderboard, setSelectedLeaderboard] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [error2, setError2] = useState(null);
  const [deleteById, setDeleteById] = useState(null);
  const { user } = useContext(AuthContext);
  const [deleteAlert, setDeleteAlert] = useState(false);
  const [leaderboardModal, setLeaderboardModal] = useState(false);
  const [leaderboardType, setLeaderboard3Type] = useState(type); // New state for type
  const deleteAlertOpen = () => setDeleteAlert(true);
  const deleteAlertClose = () => setDeleteAlert(false);
  const leaderboardModalOpen = () => setLeaderboardModal(true);
  const leaderboardModalClose = () => {
    setLeaderboardModal(false);
    setLoading(false);
    setError2("");
  };

  useEffect(() => {
    if (user && user.getIdToken) {
      (async () => {
        const userIdToken = await user.getIdToken();
        try {
          const fetchedData = await apiService.getLeaderboardData({
            userIdToken,
            type: leaderboardType, // Pass the type to the API call
          });
          setLeaderboards(fetchedData);
          setLoading(false);
        } catch (error) {
          setError("Error fetching leaderboard data: " + error.message);
          setLoading(false);
        }
      })();
    }
  }, [user, leaderboardType]);

  const handleDelete = async (id) => {
    // if (!user || !user.getIdToken) {
    //   return;
    // }
    // const userIdToken = await user.getIdToken();
    // try {
    //   await apiService.deleteLeaderboard({ userIdToken, id });
    //   const updatedLeaderboards = leaderboards.filter(
    //     (leaderboard) => leaderboard.id !== id
    //   );
    //   setLeaderboards(updatedLeaderboards);
    // } catch (error) {
    //   console.error("Error deleting warehouse manager: ", error);
    // }
  };

  const onUpdateLeaderboard = async (e) => {
    e.preventDefault();
    if (!user || !user.getIdToken) {
      return;
    }
    const userIdToken = await user.getIdToken();
    try {
      await apiService.updatedLeaderboard({
        userIdToken,
        id: selectedLeaderboard.id,
        data: selectedLeaderboard,
      });
      const updatedLeaderboards = leaderboards.map((leaderboard) =>
        leaderboard.id === selectedLeaderboard.id
          ? selectedLeaderboard
          : leaderboard
      );
      setLeaderboards(updatedLeaderboards);
      leaderboardModalClose();
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
        onClose={leaderboardModalClose}
        aria-labelledby="customized-dialog-title"
        open={leaderboardModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={leaderboardModalClose}
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
              label="Customer ID"
              type="tel"
              color="secondary"
              required
              disabled
              value={selectedLeaderboard.uid}
              onChange={(e) =>
                setSelectedLeaderboard({
                  ...selectedLeaderboard,
                  uid: e.target.value,
                })
              }
            />
            <TextField
              label="Name"
              type="cus"
              disabled
              color="secondary"
              required
              value={selectedLeaderboard.cus}
              onChange={(e) =>
                setSelectedLeaderboard({
                  ...selectedLeaderboard,
                  cus: e.target.value,
                })
              }
            />
            <TextField
              label="Rank"
              type="text"
              color="secondary"
              required
              disabled
              value={selectedLeaderboard.rank}
              onChange={(e) =>
                setSelectedLeaderboard({
                  ...selectedLeaderboard,
                  rank: e.target.value,
                })
              }
            />
            <TextField
              label="Points"
              type="number"
              color="secondary"
              required
              value={selectedLeaderboard.points}
              onChange={(e) =>
                setSelectedLeaderboard({
                  ...selectedLeaderboard,
                  points: e.target.value,
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
              onClick={onUpdateLeaderboard}
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
              { Header: "Customer ID", accessor: "uid" },
              { Header: "Name", accessor: "cus" },
              { Header: "Rank", accessor: "rank" },
              { Header: "Points", accessor: "points" },
              // { Header: "Actions", accessor: "action", align: "center" },
            ],
            rows: leaderboards.map((leaderboard) => ({
              uid: leaderboard.uid,
              cus: leaderboard.cus,
              rank: leaderboard.rank,
              points: leaderboard.points,
              // action: (
              //   <MDBox display="flex" alignItems="center">
              //     <MDButton
              //       variant="text"
              //       color={"dark"}
              //       onClick={() => {
              //         setSelectedLeaderboard(leaderboard);
              //         leaderboardModalOpen();
              //       }}
              //     >
              //       <Icon>edit</Icon>
              //       {/* &nbsp;edit */}
              //     </MDButton>
              //   </MDBox>
              // ),
            })),
          }}
        />
      )}
    </div>
  );
}

export default Leaderboards;
