require('dotenv').config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const nodemailer = require("nodemailer");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log("MongoDB connected"))
  .catch(err => console.error("MongoDB connection error:", err));

// Verification Code Schema
const verificationCodeSchema = new mongoose.Schema({
  email: { type: String, required: true, index: true },
  code: { type: String, required: true },
  expiresAt: { type: Date, default: Date.now, index: { expires: '10m' } } // auto expire
});

const VerificationCode = mongoose.model('VerificationCode', verificationCodeSchema);

// Send OTP
app.post("/send-otp", async (req, res) => {
  const { email } = req.body;
  if (!email) {
    console.log("[SEND OTP] ❌ No email provided.");
    return res.status(400).json({ message: "Email is required" });
  }

  console.log(`[SEND OTP] 📩 Processing email: ${email}`);

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000;

  try {
    const hash = await bcrypt.hash(code, 10);
    await VerificationCode.findOneAndUpdate(
      { email },
      { email, code: hash, expiresAt },
      { upsert: true, new: true }
    );

    console.log(`[SEND OTP] 🔐 OTP generated and saved: ${code}`);

    const transporter = nodemailer.createTransport({
      host:   process.env.SMTP_HOST,
      port:   +process.env.SMTP_PORT,
      secure: process.env.SMTP_PORT === '465', // true for 465, false for 587
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,          // the 16-char App Password
      },
    });

    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: "OTP for account verification",
      html: `
        <div style="background-color: #f4f4f4; padding: 30px; font-family: Arial, sans-serif;">
          <div style="max-width: 480px; margin: auto; background-color: #ffffff; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
            
            <div style="text-align: center;">
              <div style="font-size: 32px; font-weight: bold; color: #1DB954; margin-bottom: 20px;">Blip</div>
              <h2 style="color: #222; font-size: 22px; margin-bottom: 10px;">Verify Your Email</h2>
              <p style="color: #555; font-size: 16px;">Use the code below to verify your email address:</p>
              
              <div style="margin: 20px auto; font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #1DB954; background: #f0f8ff; padding: 15px 25px; border-radius: 8px; display: inline-block;">
                ${code}
              </div>

              <p style="color: #777; font-size: 14px; margin-top: 30px;">This code is valid for 10 minutes. If you didn’t request this, you can ignore this email.</p>
            </div>

            <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;" />

            <div style="text-align: center; color: #aaa; font-size: 12px;">
              © ${new Date().getFullYear()} Blip. All rights reserved.
            </div>
          </div>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log(`[SEND OTP] ✅ Email sent to: ${email}`);
    res.json({ success: true, message: "OTP sent" });
  } catch (error) {
    console.error("[SEND OTP] ❌ Error:", error);
    res.status(500).json({ success: false, message: "Failed to send OTP" });
  }
});

// Verify OTP
app.post("/verify-otp", async (req, res) => {
  const { email, code } = req.body;

  console.log("[VERIFY OTP] 📥 Request received");
  console.log("[VERIFY OTP] 📨 Email:", email);
  console.log("[VERIFY OTP] 🔢 Code entered:", code);

  if (!email || !code) {
    console.log("[VERIFY OTP] ❌ Missing email or code");
    return res.status(400).json({ message: "Email and OTP are required" });
  }

  try {
    const record = await VerificationCode.findOne({ email });

    if (!record) {
      console.log("[VERIFY OTP] ❌ No OTP record found or expired for email:", email);
      return res.status(404).json({ message: "OTP not found or expired" });
    }

    console.log("[VERIFY OTP] 🗃️ OTP record found. Checking match...");

    const match = await bcrypt.compare(code, record.code);

    if (!match) {
      console.log("[VERIFY OTP] ❌ Invalid OTP for email:", email);
      return res.status(400).json({ message: "Invalid OTP" });
    }

    console.log("[VERIFY OTP] ✅ OTP verified for:", email);
    await VerificationCode.deleteOne({ email }); // invalidate after use
    res.json({ success: true, message: "OTP verified" });
  } catch (error) {
    console.error("[VERIFY OTP] ❌ Server error:", error);
    res.status(500).json({ success: false, message: "Verification failed" });
  }
});

const loginLogSchema = new mongoose.Schema({
  email: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});

const LoginLog = mongoose.model("LoginLog", loginLogSchema);

app.post("/log-login", async (req, res) => {
  try {
    const { email, timestamp } = req.body;

    if (!email || !timestamp) {
      console.log("[LOG LOGIN] ❌ Missing email or timestamp");
      return res.status(400).json({ message: "Email and timestamp are required" });
    }

    await LoginLog.create({ email, timestamp });
    console.log(`[LOG LOGIN] ✅ Logged login for ${email} at ${timestamp}`);

    res.status(200).json({ success: true, message: "Login logged successfully" });
  } catch (error) {
    console.error("[LOG LOGIN] ❌ Error logging login:", error);
    res.status(500).json({ success: false, message: "Failed to log login" });
  }
});


// Start server
app.listen(PORT, () => {
  console.log(`OTP server running on port ${PORT}`);
});