import { createContext, useReducer, useEffect } from "react";
import AuthReducer from "./AuthReducer";

const INITIAL_STATE = {
  user: JSON.parse(localStorage.getItem("user")) || null,
  isFetching: false,
  error: false,
  feed_display_moments: false,
};

export const AuthContext = createContext(INITIAL_STATE);

export const AuthContextProvider = ({children}) => {
  const [state, dispatch] = useReducer(AuthReducer, INITIAL_STATE);

  useEffect(() => {
    localStorage.setItem("user", JSON.stringify(state.user))
  }, [state.user]);
  
  return (
    <AuthContext.Provider value={{
      user: state.user, 
      isFetching: state.isFetching,
      error: state.error,
      dispatch,
      feed_display_moments: false
    }} >
      {children}
    </AuthContext.Provider>
  );
}