import React, { useEffect, useState, useContext } from "react";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth } from "../../../firebase";
import Card from "@mui/material/Card";
import MDBox from "components/MDBox";
import MDTypography from "components/MDTypography";
import MDInput from "components/MDInput";
import MDButton from "components/MDButton";
import {
  CircularProgress,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  TextField,
} from "@mui/material";
import { green } from "@mui/material/colors";
import BasicLayout from "layouts/authentication/BasicLayout";
import * as apiService from "../../api-service";
import { AuthContext } from "../../../context/AuthContext";

function RiderSignup() {
  const [loading, setLoading] = useState(false);
  const [signupError, setSignupError] = useState(false);
  const [dbareas, setdbAreas] = useState([]);
  const [userIdToken, setUserIdToken] = useState("");
  const { user } = useContext(AuthContext);

  useEffect(() => {
    (async () => {
      try {
        const userIdToken = await user.getIdToken();
        setUserIdToken(userIdToken);
        const fetchedData = await apiService.getAreasData({ userIdToken });
        console.log("Fetched data:", fetchedData);
        setdbAreas(fetchedData);
      } catch (error) {
        console.error("Error fetching areas: ", error);
      }
    })();
  }, [user]);

  const [signupUser, setSignupUser] = useState({
    email: "",
    password: "",
    name: "",
    phone: "",
    address: "",
    idCard: "",
    area: "",
    vehicleNumber: "",
    role: "rider",
    uid: "",
  });

  const handleSignup = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const newUser = await createUserWithEmailAndPassword(
        auth,
        signupUser.email,
        signupUser.password
      );

      const riderData = {
        email: signupUser.email,
        role: "rider",
        name: signupUser.name,
        uid: newUser.user.uid,
        phone: signupUser.phone,
        address: signupUser.address,
        idCard: signupUser.idCard,
        area: signupUser.area,
        vehicleNumber: signupUser.vehicleNumber,
      };

      await apiService.signup({ userIdToken, data: riderData });

      setSignupUser({
        email: "",
        password: "",
        name: "",
        phone: "",
        address: "",
        idCard: "",
        area: "",
        vehicleNumber: "",
        role: "rider",
        uid: "",
      });

      setLoading(false);
    } catch (error) {
      setSignupError(error.code);
      setLoading(false);
    }
  };

  return (
    <BasicLayout>
      <div
        style={{
          height: "100vh",
          overflowY: "scroll",
          position: "relative",
          marginTop: "25%",
        }}
      >
        <Card scroll>
          <MDBox
            variant="gradient"
            bgColor="info"
            borderRadius="lg"
            coloredShadow="info"
            mx={2}
            mt={-3}
            p={2}
            mb={1}
            textAlign="center"
          >
            <MDTypography variant="h5" fontWeight="medium" color="white" mt={1}>
              Add Rider
            </MDTypography>
          </MDBox>
          <MDBox pt={4} pb={3} px={3}>
            {signupError && (
              <MDBox mb={2} p={1}>
                <TextField
                  fullWidth
                  InputProps={{ readOnly: true }}
                  error
                  label="Error"
                  value={signupError}
                  variant="standard"
                />
              </MDBox>
            )}

            <form onSubmit={handleSignup}>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.name}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, name: e.target.value })
                  }
                  type="text"
                  label="Name"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.email}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, email: e.target.value })
                  }
                  type="email"
                  label="Email"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.password}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, password: e.target.value })
                  }
                  type="password"
                  label="Password"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.idCard}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, idCard: e.target.value })
                  }
                  type="number"
                  label="ID Card Number"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.phone}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, phone: e.target.value })
                  }
                  type="number"
                  label="Phone"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.address}
                  onChange={(e) =>
                    setSignupUser({ ...signupUser, address: e.target.value })
                  }
                  type="text"
                  label="Address"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <MDInput
                  value={signupUser.vehicleNumber}
                  onChange={(e) =>
                    setSignupUser({
                      ...signupUser,
                      vehicleNumber: e.target.value,
                    })
                  }
                  type="text"
                  label="Vehicle Number"
                  variant="standard"
                  fullWidth
                  required
                />
              </MDBox>
              <MDBox mb={2}>
                <FormControl fullWidth variant="standard">
                  <InputLabel>Select Area</InputLabel>
                  <Select
                    value={signupUser.area}
                    onChange={(e) =>
                      setSignupUser({ ...signupUser, area: e.target.value })
                    }
                  >
                    {dbareas.map((area) => (
                      <MenuItem key={area.id} value={area.id}>
                        {area.location}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </MDBox>
              <MDBox
                mt={4}
                mb={1}
                sx={{
                  display: "flex",
                  direction: "row",
                  justifyContent: "center",
                }}
              >
                {loading ? (
                  <CircularProgress
                    size={30}
                    sx={{ color: green[500], justifyContent: "center" }}
                  />
                ) : (
                  <MDButton
                    variant="gradient"
                    color="info"
                    fullWidth
                    type="submit"
                  >
                    SIGN UP A RIDER
                  </MDButton>
                )}
              </MDBox>
            </form>
          </MDBox>
        </Card>
      </div>
    </BasicLayout>
  );
}

export default RiderSignup;
