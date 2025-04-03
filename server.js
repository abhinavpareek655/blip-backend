require('dotenv').config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const multer = require("multer");
const path = require("path");
const app = express();
const PORT = process.env.PORT || 5000;
const nodemailer = require('nodemailer');

// Middleware
app.use(cors());
app.use(express.json()); // bodyParser is deprecated in express 4.16+

// Database Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  retryWrites: true,
  w: "majority"
})
.then(() => console.log("MongoDB Connected"))
.catch(err => console.error("MongoDB Connection Error:", err));

// User Schema
const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, "Username is required"],
    unique: true,
    trim: true,
    minlength: 3
  },
  email: {
    type: String,
    required: [true, "Email is required"],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, "Invalid email format"]
  },
  passwordHash: {
    type: String,
    required: [true, "Password is required"],
    minlength: 8
  }
});

const User = mongoose.model("User", userSchema);

// Post Schema

const postSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text: String,
  mediaType: { type: String, enum: ['image', 'video', null] },
  mediaUrl: String,
  isPublic: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

const Post = mongoose.model('Post', postSchema);

const verificationCodeSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    index: true
  },
  code: {
    type: String,
    required: true
  },
  expiresAt: {
    type: Date,
    default: Date.now,
    index: { expires: '10m' } // Auto-delete after 10 minutes
  }
});

const VerificationCode = mongoose.model('VerificationCode', verificationCodeSchema);


// Send Verification Code Endpoint
app.post('/send-reset-code', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    console.log(email);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 600000;

    try {
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(code, salt);

        await VerificationCode.findOneAndUpdate(
            { email },
            { email, code: hash, expiresAt }, 
            { new: true, upsert: true }
        );
    } catch (error) {
        console.error('Error generating OTP:', error);
        return res.status(500).json({ success: false, error: 'Server error' });
    }

    const auth = nodemailer.createTransport({
        service: 'gmail',
        secure: true,
        port: 465,
        auth: {
            user: '2022btcse002@curaj.ac.in',
            pass: process.env.PASSWORD // Fix incorrect env variable usage
        }
    });

    const mailOptions = {
        from: '2022btcse002@curaj.ac.in',
        to: email,
        subject: 'OTP for account verification',
        html: `
            <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px; background-color: #f4f4f4;">
                <div style="max-width: 400px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);">
                    <h2 style="color: #333;">Your OTP Code</h2>
                    <p style="font-size: 18px; color: #555;">Use the code below to complete your verification:</p>
                    <div style="font-size: 24px; font-weight: bold; color: #1DB954; padding: 10px; background: #f0f8ff; border-radius: 5px; display: inline-block;">
                        ${code}
                    </div>
                    <p style="color: #888; margin-top: 10px;">This code will expire in 10 minutes.</p>
                </div>
            </div>
        `
    };

    auth.sendMail(mailOptions, (error, info) => {
      if (error) {
          console.error('Error sending email:', error);
          return res.status(500).json({ success: false, error: 'Server error' });
      }
      return res.status(200).json({ success: true, message: 'OTP sent successfully' });
  });

    res.json({ success: true });
  } catch (error) {
    console.error('Send code error:', error);
    res.status(500).json({ message: 'Failed to send verification code' });
  }
});

// Verify Code Endpoint
app.post('/verify-reset-code', async (req, res) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
        return res.status(400).json({ success: false, error: 'Email and OTP are required' });
    }
    
    const userOTP = await UserOTPs.findOne({ email });

    if (!userOTP) {
        return res.status(404).json({ success: false, error: 'User not found' });
    }
    if (userOTP.expiry < Date.now()) {
        return res.status(400).json({ success: false, error: 'OTP expired' });
    }

    const isMatch = await bcrypt.compare(otp, userOTP.otp); // Compare plain OTP with hashed OTP
    if (isMatch) {
        return res.status(200).json({ success: true, message: 'User verified successfully' });
    } else {
        return res.status(400).json({ success: false, error: 'Invalid OTP' });
    }
    // Generate temporary token for password reset
    // const tempToken = jwt.sign(
    //   { email, code },
    //   process.env.JWT_SECRET,
    //   { expiresIn: '15m' }
    // );

    // res.json({ success: true, tempToken });
    
  } catch (error) {
    res.status(500).json({ message: 'Verification failed' });
  }
});

// File Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only images and videos are allowed!'));
    }
  }
});

// Health Check
app.get("/", (req, res) => {
  res.status(200).json({ status: "ok", message: "Server is running" });
});

// Authentication Middleware
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Authentication required' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};

// Signup Route
app.post("/signup", async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Validation
    if (!username || !email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: "Password must be at least 8 characters" });
    }

    // Check existing user
    const existingUser = await User.findOne({ 
      $or: [{ email }, { username }] 
    });

    if (existingUser) {
      const field = existingUser.email === email ? "email" : "username";
      return res.status(409).json({ message: `${field} already in use` });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    const newUser = new User({
      username: username.trim(),
      email: email.toLowerCase().trim(),
      passwordHash
    });

    await newUser.save();

    // Generate JWT
    const token = jwt.sign(
      { userId: newUser._id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "1h" }
    );

    // Secure response
    res.status(201).json({
      message: "User registered successfully",
      token,
      user: {
        id: newUser._id,
        username: newUser.username,
        email: newUser.email
      }
    });
  } catch (error) {
    console.error("Signup Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

//Login Route
app.post('/login', async (req, res) => {
    try {
      const { username, password } = req.body;

      const user = await User.findOne({ 
        $or: [{ username }, { email: username }] 
      });
  
      if (!user) return res.status(404).json({ message: 'User not found' });
  
      const validPassword = await bcrypt.compare(password, user.passwordHash);
      if (!validPassword) return res.status(401).json({ message: 'Invalid password' });
  
      const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { 
        expiresIn: process.env.JWT_EXPIRES_IN 
      });
  
      res.json({ token });
    } catch (error) {
      res.status(500).json({ message: 'Server error' });
    }
});

// Post Routes
app.post('/posts', authenticate, upload.single('media'), async (req, res) => {
  try {
    const { text, isPublic, mediaType } = req.body;
    
    if (!text?.trim() && !req.file) {
      return res.status(400).json({ message: 'Content or media required' });
    }

    const post = await Post.create({
      user: req.userId,
      text: text?.trim(),
      mediaType: req.file ? mediaType : null,
      mediaUrl: req.file ? `${process.env.BASE_URL}/${req.file.path}` : null,
      isPublic: isPublic === 'true'
    });

    res.status(201).json(post);
  } catch (error) {
    res.status(500).json({ message: 'Error creating post' });
  }
});

app.get('/posts', authenticate, async (req, res) => {
  try {
    const posts = await Post.find({ isPublic: true })
      .populate('user', 'username')
      .sort({ createdAt: -1 });
      
    res.json(posts);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching posts' });
  }
});


// Start Server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
});