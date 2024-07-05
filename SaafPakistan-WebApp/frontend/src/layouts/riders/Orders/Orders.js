import { Grid, Card } from "@mui/material";
import MDBox from "components/MDBox";
import MDTypography from "components/MDTypography";
import DashboardLayout from "examples/LayoutContainers/DashboardLayout";
import DashboardNavbar from "examples/Navbars/DashboardNavbar";
import GetRidersOrders from "../data/getRidersOrders";

function RiderOrders() {
  return (
    <DashboardLayout>
      <DashboardNavbar />
      <MDBox py={3}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Card>
              <MDBox pt={3} px={2}>
                <MDTypography
                  variant="h6"
                  fontWeight="medium"
                  sx={{ textAlign: "center" }}
                ></MDTypography>
              </MDBox>
              <MDBox pt={1} pb={2} px={2}>
                <MDBox
                  component="ul"
                  display="flex"
                  flexDirection="column"
                  p={0}
                  m={0}
                >
                  <GetRidersOrders></GetRidersOrders>
                </MDBox>
              </MDBox>
            </Card>
          </Grid>
        </Grid>
      </MDBox>
    </DashboardLayout>
  );
}

export default RiderOrders;
