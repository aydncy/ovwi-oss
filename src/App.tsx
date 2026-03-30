import { useEffect, useState } from "react";
import { handleAuth } from "./lib/auth";
import { Dashboard } from "./components/Dashboard/Dashboard";
import Landing from "./Landing";
import OVWI from "./ovwi/OVWI";

function ClinicFlowAC() {
  return (
    <div style={{ padding: 40 }}>
      <h1>ClinicFlowAC</h1>
      <a href="/app"><button>Open Dashboard</button></a>
    </div>
  );
}

export default function App() {
  const [ready, setReady] = useState(false);
  const path = window.location.pathname;

  useEffect(() => {
    (async () => {
      await handleAuth();
      setReady(true);
    })();
  }, []);

  if (!ready) return <p>Loading...</p>;

  if (path === "/app") return <Dashboard />;
  if (path === "/ovwi") return <OVWI />;
  if (path === "/clinicflowac") return <ClinicFlowAC />;

  return <Landing />;
}
