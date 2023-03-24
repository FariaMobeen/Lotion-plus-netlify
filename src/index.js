import ReactDOM from "react-dom";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./index.css";
import Layout from "./Layout";
import WriteBox from "./WriteBox";
import Empty from "./Empty";
import reportWebVitals from "./reportWebVitals";
import { GoogleOAuthProvider } from '@react-oauth/google';
import App from './App';
import React from 'react';


const renderApp = () => {
  
  ReactDOM.render(
    <React.StrictMode> 
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Empty />} />
          <Route path="/notes" element={<Empty />} />
          <Route
            path="/notes/:noteId/edit"
            element={<WriteBox edit={true} />}
          />
          <Route path="/notes/:noteId" element={<WriteBox edit={false} />} />
          {/* any other path */}
          <Route path="*" element={<Empty />} />
        </Route>
      </Routes>
    </BrowserRouter>
    </React.StrictMode>,
    document.getElementById('root')
);
}
ReactDOM.createRoot(document.getElementById("root")).render(
  <GoogleOAuthProvider clientId="623221484879-m1v3hiaii9mja46mpdeckqr11vsfogef.apps.googleusercontent.com">
          <App onLogin = {renderApp}/>
  </GoogleOAuthProvider>,

);

reportWebVitals();
