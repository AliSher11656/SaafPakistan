import DashboardLayout from "examples/LayoutContainers/DashboardLayout";
import DashboardNavbar from "examples/Navbars/DashboardNavbar";
import Recyclables from "./data/getRecyclables";
import { Card, Grid, Icon } from "@mui/material";

import MDBox from "components/MDBox";
import MDTypography from "components/MDTypography";
import MDButton from "components/MDButton";
import React, { useContext, useState } from "react";
import styled from "styled-components";
import CloseIcon from "@mui/icons-material/Close";
import PropTypes from "prop-types";

import {
  CircularProgress,
  IconButton,
  DialogActions,
  Dialog,
  DialogTitle,
  DialogContent,
  Typography,
  Box,
  TextField,
} from "@mui/material";
import { green } from "@mui/material/colors";
import * as apiService from "../api-service";
import { AuthContext } from "../../context/AuthContext";

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

function Recyclable() {
  const [recyclableModal, setRecyclableModal] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const { user } = useContext(AuthContext);
  const [recyclablesData, setRecyclablesData] = useState({
    item: "",
    price: "",
  });
  const [refreshRecyclables, setRefreshRecyclables] = useState(false);

  const onAddRecyclable = async () => {
    setLoading(true);
    setError("");
    if (user && user.getIdToken) {
      const token = await user.getIdToken();
      try {
        if (!recyclablesData.item.trim()) {
          throw new Error("Recyclable name cannot be empty");
        }

        await apiService.createRecyclable({
          userIdToken: token,
          data: recyclablesData,
        });

        recyclableModalClose();
        setRecyclableModal(false);
        setLoading(false);
        setError("");
        setRecyclablesData({ item: "" });

        setRefreshRecyclables(!refreshRecyclables);
      } catch (error) {
        setLoading(false);
        setError(error.response.data.error || error.message);
      }
    }
  };

  const recyclableModalOpen = () => setRecyclableModal(true);
  const recyclableModalClose = () => {
    setRecyclableModal(false);
    setLoading(false);
    setError("");
  };

  return (
    <>
      <BootstrapDialog
        onClose={recyclableModalClose}
        aria-labelledby="customized-dialog-title"
        open={recyclableModal}
      >
        <BootstrapDialogTitle
          id="customized-dialog-title"
          onClose={recyclableModalClose}
        >
          <Typography
            variant="h3"
            color="secondary.main"
            sx={{ pt: 1, textAlign: "center" }}
          >
            Add Recyclable
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
              label="Item Name"
              type="text"
              rows={1}
              color="secondary"
              required
              value={recyclablesData.item}
              onChange={(e) =>
                setRecyclablesData({
                  ...recyclablesData,
                  item: e.target.value,
                })
              }
            />
            <TextField
              label="Individuals Price"
              type="number"
              rows={1}
              color="secondary"
              required
              value={recyclablesData.price}
              onChange={(e) =>
                setRecyclablesData({
                  ...recyclablesData,
                  price: e.target.value,
                })
              }
            />

            <TextField
              label="Bussinesses Price"
              type="number"
              rows={1}
              color="secondary"
              required
              value={recyclablesData.bizPrice}
              onChange={(e) =>
                setRecyclablesData({
                  ...recyclablesData,
                  bizPrice: e.target.value,
                })
              }
            />
            {error === "" ? null : (
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
                  // defaultValue="Invalid Data!"
                  value={error}
                  variant="standard"
                />
              </MDBox>
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
              onClick={onAddRecyclable}
            >
              Save
            </MDButton>
          )}
        </DialogActions>
      </BootstrapDialog>
      <DashboardLayout>
        <DashboardNavbar />
        <MDBox py={3}>
          <MDBox>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Card>
                  <MDBox
                    mx={2}
                    mt={-3}
                    py={3}
                    px={2}
                    variant="gradient"
                    bgColor="info"
                    borderRadius="lg"
                    coloredShadow="info"
                  >
                    <MDBox
                      pt={2}
                      pb={2}
                      px={2}
                      display="flex"
                      justifyContent="space-between"
                      alignItems="center"
                    >
                      <MDTypography
                        variant="h6"
                        fontWeight="medium"
                        color="white"
                      >
                        All Recyclables
                      </MDTypography>
                      <MDButton
                        variant="gradient"
                        color="light"
                        onClick={() => {
                          recyclableModalOpen();
                        }}
                      >
                        <Icon sx={{ fontWeight: "bold" }}>add</Icon>
                        &nbsp;ADD RECYCLABLE ITEM
                      </MDButton>
                    </MDBox>
                  </MDBox>
                  <div>
                    {/* Pass refreshRecyclables as a prop to Recyclables component */}
                    <Recyclables refreshRecyclables={refreshRecyclables} />
                  </div>
                </Card>
              </Grid>
            </Grid>
          </MDBox>
        </MDBox>
      </DashboardLayout>
    </>
  );
}

export default Recyclable;
