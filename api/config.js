module.exports = function handler(_req, res) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabasePublicKey = process.env.SUPABASE_PUBLIC_KEY;

  if (!supabaseUrl || !supabasePublicKey) {
    res.status(500).json({
      error: "SUPABASE_URL and SUPABASE_PUBLIC_KEY must be configured in Vercel."
    });
    return;
  }

  res.setHeader("Cache-Control", "no-store");
  res.status(200).json({
    supabaseUrl,
    supabasePublicKey
  });
};
