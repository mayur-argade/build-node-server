
# Function to display a message with a colored background
function colored_message() {
  local message="$1"
  local color="$2"
  echo -e "${color}${message}$(tput sgr0)"
}

# Function to display a loading spinner
function show_spinner() {
  local -r pid="$1"
  local -r delay=0.75
  local spinstr='|/-\'
  while ps a | awk '{print $1}' | grep -q "$pid"; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

function prompt_additional_dependencies() {
  read -p "$(colored_message '❓ Do you want to install additional dependencies? (y/n): ' $GREEN)" install_additional
  if [[ $install_additional == "y" || $install_additional == "Y" ]]; then
    read -p "$(colored_message '🔧 Enter additional dependencies (space-separated): ' $GREEN)" additional_dependencies
    if [[ ! -z "$additional_dependencies" ]]; then
      echo -e "$(colored_message '🔧 Step 6: Installing additional dependencies...' $GREEN)"
      npm install $additional_dependencies --silent &
      show_spinner $!
    fi
  fi
}

# Colors for console output
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
NC=$(tput sgr0) # No Color


# Prompt user for folder name (default: backend)
read -p "$(colored_message '📁 Enter folder name (default: server): ' $BLUE)" folder_name
folder_name=${folder_name:-server}

# Check if the folder already exists
while [ -d "$folder_name" ]; do
  read -p "$(colored_message '⚠️ Folder '$folder_name' already exists. Please enter another folder name: ' $RED)" folder_name
done

# Step 1: Create necessary folders
echo -e "$(colored_message '📂 Step 1: Creating necessary file & folders...' $GREEN)"
mkdir $folder_name
cd $folder_name
mkdir models views controllers config middleware routes

# Step 2: Create necessary files
touch index.js app.js .gitignore .env

# Step 3: Initialize npm
echo -e "$(colored_message '📦 Step 2: Initializing npm...' $GREEN)"
npm init -y

# Modify package.json scripts
sed -i 's/"test": "echo \\"Error: no test specified\\" && exit 1"/"start": "node index.js",\n    "dev": "nodemon index.js"/' package.json

# List of default dependencies to be installed
default_dependencies=("express" "mongoose" "dotenv" "morgan" "validator" "ejs")
echo -e "$(colored_message '📦 Step 3: Default Dependencies to be Installed:' $GREEN)"
echo -e "${default_dependencies[@]/#/  - }"

# Step 4: Install default dependencies
npm install ${default_dependencies[@]} --silent &   # or npm install ${default_dependencies[@]} -s &
show_spinner $!

# Step 5: Install dev dependency nodemon
echo -e "$(colored_message '📦 Installing dev dependency nodemon...' $GREEN)"
npm install nodemon -D --silent >/dev/null &   # or npm install nodemon -D -s >/dev/null &
show_spinner $!

# Prompt user for additional dependencies
prompt_additional_dependencies

# Step 6: Write the code to index.js
echo -e "$(colored_message '📝 Step 4: Writing starter templete ' $GREEN)"
cat << 'EOF' > index.js
const app = require('./app');
const connectdb = require('./config/connectdb');

require('dotenv').config();

// Connection with the database
connectdb();

// Creating a basic server
app.listen(process.env.PORT || 3000, () => {
  console.log(`Server is running at port: ${process.env.PORT || 3000} 🚀`);
});
EOF

# Step 7: Write the code to app.js
cat << 'EOF' > app.js
cat << 'EOF' > app.js
const express = require('express');
const app = express();
const morgan = require('morgan');

// Morgan middleware
app.use(morgan('tiny'));

// Regular middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Set up EJS as the render engine
app.set('view engine', 'ejs');

// Import all the routes here
const home = require('./routes/HomeRoute');
const user = require('./routes/UserRoute');

// Router middleware
app.use('/api/v1', home);
app.use('/api/v1', user);

module.exports = app;
EOF

# Step 8: Write the code to HomeController.js
cat << 'EOF' > controllers/HomeController.js
exports.home = (req, res) => {
  res.status(200).json({
    success: true,
    greeting: 'Home controller working OK',
  });
};
EOF

# Step 9: Write the code to HomeRoute.js
cat << 'EOF' > routes/HomeRoute.js
const express = require('express');
const router = express.Router();
const { home } = require('../controllers/HomeController');

router.route('/').get(home);

module.exports = router;
EOF

# Step 10: Write the code to UserModel.js
cat << 'EOF' > models/UserModel.js
const mongoose = require('mongoose');
const validator = require('validator');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a name'],
    maxLength: [40, 'Name should be under 40 characters'],
  },
  email: {
    type: String,
    required: [true, 'Please provide an email'],
    validate: [validator.isEmail, 'Please enter email in the correct format'],
    unique: true,
  },
});

module.exports = mongoose.model('User', userSchema);
EOF

# Step 11: Write the code to UserController.js
cat << 'EOF' > controllers/UserController.js
const User = require('../models/UserModel');

exports.registerUser = async (req, res) => {
  try {
    const { name, email } = req.body;

    const user = await User.create({
      name,
      email,
    });

    res.status(200).json(user);
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: 'Something went wrong' });
  }
};
EOF

# Step 12: Write the code to UserRoute.js
cat << 'EOF' > routes/UserRoute.js
const express = require('express');
const router = express.Router();
const { registerUser } = require('../controllers/UserController');

router.route('/signup').post(registerUser);

module.exports = router;
EOF

# Step 13: Write the code to connectdb.js
cat << 'EOF' > config/connectdb.js
const mongoose = require('mongoose');

const connectdb = () => {
  mongoose.set('strictQuery', false);
  mongoose
    .connect(process.env.MONGO_URL, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => {
      console.log('DB connection successful.. ✌');
    })
    .catch((error) => {
      console.log('DB connection failed');
      console.log(error);
      process.exit(1);
    });
};

module.exports = connectdb;
EOF

# Step 14: Update the .gitignore file
cat << 'EOF' > .gitignore
node_modules
.env
EOF

# Step 15: Create .env file
cat << 'EOF' > .env
PORT=3000
MONGO_URL=mongodb://your_mongodb_connection_string_here
EOF

# # Step 16: Change directory and start the server
# cd ..
# npm run dev

# Final step: End of the script
echo -e "$(colored_message '🎉 Backend project structure and files created successfully in the '"$folder_name"' folder!' $BLUE)"
echo -e "$(colored_message '📝 change mongodb connection url in the .env file' $BLUE)"
echo -e "$(colored_message '💻 You can now start your backend server using the following command:' $BLUE)"
echo -e "$(colored_message '💻 cd '"$folder_name"' && npm run dev' $GREEN)"
