import React, { useState } from "react";
import DashboardLayout from "examples/LayoutContainers/DashboardLayout";
import DashboardNavbar from "examples/Navbars/DashboardNavbar";
import Leaderboards from "./data/getLeaderboards";
import { Card, Grid } from "@mui/material";
import MDBox from "components/MDBox";
import MDTypography from "components/MDTypography";
import MDButton from "components/MDButton";

function Leaderboard() {
  const [leaderboardType, setLeaderboardType] = useState("Personal");

  const handlePersonalLeaderboard = () => {
    setLeaderboardType("Personal");
  };

  const handleCompanyLeaderboard = () => {
    setLeaderboardType("Company");
  };

  return (
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
                      Leaderboards
                    </MDTypography>
                  </MDBox>
                  <MDBox
                    pt={2}
                    pb={2}
                    px={2}
                    display="flex"
                    justifyContent="space-around"
                    alignItems="center"
                  >
                    <MDButton
                      onClick={handlePersonalLeaderboard}
                      variant={
                        leaderboardType === "Personal"
                          ? "contained"
                          : "outlined"
                      }
                    >
                      Individuals Leaderboard
                    </MDButton>
                    <MDButton
                      onClick={handleCompanyLeaderboard}
                      variant={
                        leaderboardType === "Company" ? "contained" : "outlined"
                      }
                    >
                      Company Leaderboard
                    </MDButton>
                  </MDBox>
                </MDBox>
                <div>
                  {leaderboardType === "Personal" && (
                    <Leaderboards type="Personal" />
                  )}
                  {leaderboardType === "Company" && (
                    <Leaderboards type="Company" />
                  )}
                </div>
              </Card>
            </Grid>
          </Grid>
        </MDBox>
      </MDBox>
    </DashboardLayout>
  );
}

export default Leaderboard;
