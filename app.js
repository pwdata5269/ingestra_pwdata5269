import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const statusPill = document.getElementById("status-pill");
const signInButton = document.getElementById("sign-in-button");
const signOutButton = document.getElementById("sign-out-button");
const currentUrl = document.getElementById("current-url");
const supabaseUrlOutput = document.getElementById("supabase-url");
const userEmailOutput = document.getElementById("user-email");
const providerNameOutput = document.getElementById("provider-name");
const sessionOutput = document.getElementById("session-output");
const errorOutput = document.getElementById("error-output");

currentUrl.textContent = window.location.href;

function setStatus(text, tone) {
  statusPill.textContent = text;
  statusPill.className = `pill ${tone}`;
}

function showError(message) {
  errorOutput.textContent = message;
  setStatus("Error", "pill-error");
}

function showSession(session) {
  if (!session) {
    userEmailOutput.textContent = "Not signed in";
    providerNameOutput.textContent = "Unknown";
    sessionOutput.textContent = "No active session.";
    setStatus("Signed out", "pill-waiting");
    return;
  }

  userEmailOutput.textContent = session.user?.email ?? "Unknown";
  providerNameOutput.textContent = session.user?.app_metadata?.provider ?? "Unknown";
  sessionOutput.textContent = JSON.stringify(
    {
      access_token_expires_at: session.expires_at,
      provider: session.user?.app_metadata?.provider,
      user: {
        id: session.user?.id,
        email: session.user?.email
      }
    },
    null,
    2
  );
  setStatus("Signed in", "pill-success");
}

async function main() {
  setStatus("Loading", "pill-waiting");

  const config = window.INGESTRA_RUNTIME_CONFIG;
  if (!config?.supabaseUrl || !config?.supabasePublicKey) {
    showError("SUPABASE_URL and SUPABASE_PUBLIC_KEY must be present in runtime-config.js.");
    return;
  }

  if (config.error) {
    showError(config.error);
    return;
  }

  supabaseUrlOutput.textContent = config.supabaseUrl;

  const supabase = createClient(config.supabaseUrl, config.supabasePublicKey, {
    auth: {
      flowType: "pkce",
      detectSessionInUrl: true
    }
  });

  const hashParams = new URLSearchParams(window.location.hash.startsWith("#") ? window.location.hash.slice(1) : "");
  if (hashParams.get("error_description")) {
    showError(hashParams.get("error_description"));
  } else {
    errorOutput.textContent = "None";
  }

  const {
    data: { session },
    error: sessionError
  } = await supabase.auth.getSession();

  if (sessionError) {
    showError(sessionError.message);
  } else {
    showSession(session);
  }

  supabase.auth.onAuthStateChange((_event, updatedSession) => {
    showSession(updatedSession);
  });

  signInButton.addEventListener("click", async () => {
    setStatus("Redirecting", "pill-waiting");
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "azure",
      options: {
        redirectTo: window.location.origin + "/"
      }
    });

    if (error) {
      showError(error.message);
    }
  });

  signOutButton.addEventListener("click", async () => {
    const { error } = await supabase.auth.signOut();
    if (error) {
      showError(error.message);
    } else {
      errorOutput.textContent = "None";
      showSession(null);
    }
  });
}

main().catch((error) => {
  showError(error.message);
});
