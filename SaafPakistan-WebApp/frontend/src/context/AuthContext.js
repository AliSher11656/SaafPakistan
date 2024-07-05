import { createContext, useReducer, useEffect } from "react";
import { getAuth } from "firebase/auth";
import { useAuthState } from "react-firebase-hooks/auth";

const initialState = {
  currentUser: JSON.parse(localStorage.getItem("user")) || null,
  role: JSON.parse(localStorage.getItem("role")) || null,
};

//reducer

function AuthReducer(state, action) {
  switch (action.type) {
    case "LOGIN": {
      return {
        currentUser: action.payload,
      };
    }
    case "LOGOUT": {
      return {
        currentUser: localStorage.removeItem("user") || null,
      };
    }
    case "LOGIN_ROLE": {
      return {
        role: action.payload,
      };
    }
    case "LOGOUT_ROLE": {
      return {
        role: localStorage.removeItem("role") || null,
      };
    }
    default: {
      return state;
    }
  }
}

export const AuthContext = createContext(initialState);

export const AuthContextProvider = ({ children }) => {
  const auth = getAuth();
  const [user] = useAuthState(auth);
  const [state, dispatchAuth] = useReducer(AuthReducer, initialState);
  const [roleState, dispatchAuthRole] = useReducer(AuthReducer, initialState);
  useEffect(() => {
    localStorage.setItem("user", JSON.stringify(state.currentUser));
  }, [state.currentUser]);

  useEffect(() => {
    localStorage.setItem("role", JSON.stringify(roleState.role));
  }, [roleState.role]);

  return (
    <AuthContext.Provider
      value={{
        user: user,
        currentUser: state.currentUser,
        role: roleState.role,
        dispatchAuth,
        dispatchAuthRole,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
