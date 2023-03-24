import React, { useState, useEffect } from 'react';
import { googleLogout, useGoogleLogin } from '@react-oauth/google';
import axios from 'axios';
import Layout from './Layout';




function App({onLogin}) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [collapse, setCollapse] = useState(false);
  
  const login = useGoogleLogin({

    onSuccess: (codeResponse) => {
      setUser(codeResponse);
      localStorage.setItem("accessToken", codeResponse.access_token);
      console.log("stringgg")
      console.log(user);
    },
    onError: (error) => console.log("Login Failed:", error),
  });


  useEffect(() => {
    const accessToken = localStorage.getItem("accessToken");


    if (accessToken) {
      axios
        .get(`https://www.googleapis.com/oauth2/v1/userinfo?access_token=${accessToken}`, {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            Accept: 'application/json'
          }
        })
        .then((res) => {
          setProfile(res.data);
          console.log(res.data);
          onLogin && onLogin();
        })
        .catch((err) => console.log(err));
    
      }
  }, [user, onLogin]);


  const logOut = () => {
    googleLogout();
    setProfile(null);
    setUser(null);
    localStorage.removeItem("accessToken");
  };


  return (
    <div>
      <header>
        <aside>
          <button id="menu-button" onClick={() => setCollapse(!collapse)}>
            &#9776;
          </button>
        </aside>
        <div id="app-header">
          <h1>
           Lotion
          </h1>
          <h6 id="app-moto">Like Notion, but worse.</h6>
        </div>
        <aside>&nbsp;</aside>
      </header>
     
   
       
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
      <button
  onClick={() => login()}
  style={{
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    border: '2px solid black',
    borderRadius: '5px',
    padding: '10px',
    margin: 'auto',
  }}
>
  Sign in with Google 🚀
</button>


</div>


    </div>
  );
}


export default App;


