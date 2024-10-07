#!/bin/bash

# Variables
PORT=22008
MACHINE="paffenroth-23.dyn.wpi.edu"
STUDENT_ADMIN_KEY_PATH="/mnt/c/Users/yashm/Desktop/MLOPS-cs2/Git_ChatBot_Sync_Hugging_face"
SSH_PATH="/mnt/c/Users/yashm/"
REPO_URL="https://github.com/YashMalviya16/Git_ChatBot_Sync_Hugging_face.git"
PROJECT_DIR="Git_ChatBot_Sync_Hugging_face"
TMP_DIR="/mnt/c/Users/yashm/Desktop/MLOPS-cs2/Git_ChatBot_Sync_Hugging_face/tmp"
REMOTE_PROJECT_PATH="~/project1"

# Step 0: Check if student-admin_key exists
if [ -f "${STUDENT_ADMIN_KEY_PATH}/student-admin_key" ]; then
    if [ ! -f "${STUDENT_ADMIN_KEY_PATH}/student-admin_key.pub" ]; then
        ssh-keygen -y -f "${STUDENT_ADMIN_KEY_PATH}/student-admin_key" > "${STUDENT_ADMIN_KEY_PATH}/student-admin_key.pub"
    fi
else
    echo "Error: Private key student-admin_key not found!"
    exit 1
fi

# Step 1: Clean up known_hosts and previous runs
if [ -f "${SSH_PATH}.ssh/known_hosts" ]; then
    ssh-keygen -f "${SSH_PATH}.ssh/known_hosts" -R "[${MACHINE}]:${PORT}"
fi
rm -rf $TMP_DIR

# Step 2: Set up temporary directory and copy keys
mkdir $TMP_DIR
if [ -f "${STUDENT_ADMIN_KEY_PATH}/student-admin_key" ] && [ -f "${STUDENT_ADMIN_KEY_PATH}/student-admin_key.pub" ]; then
    cp "${STUDENT_ADMIN_KEY_PATH}/student-admin_key" $TMP_DIR
    cp "${STUDENT_ADMIN_KEY_PATH}/student-admin_key.pub" $TMP_DIR
else
    echo "Error: student-admin_key or student-admin_key.pub not found!"
    exit 1
fi

# Step 3: Set permissions for the key (Fix permissions)
chmod 600 "${STUDENT_ADMIN_KEY_PATH}/student-admin_key"  # Fix for too-open permissions
cd $TMP_DIR
chmod 600 student-admin_key
chmod 644 student-admin_key.pub

# Step 4: Generate a new SSH key
if ssh-keygen -f my_key -t ed25519 -N "team8gry"; then
    echo "SSH key generated successfully."
else
    echo "Error generating SSH key!"
    exit 1
fi

# Step 5: Set correct permissions for new keys (Fix permissions)
chmod 600 my_key
chmod 644 my_key.pub

# Step 6: Update authorized_keys locally
mkdir -p "${SSH_PATH}.ssh"
cat my_key.pub > "${SSH_PATH}.ssh/authorized_keys"
cat student-admin_key.pub >> "${SSH_PATH}.ssh/authorized_keys"
chmod 600 "${SSH_PATH}.ssh/authorized_keys"

# Step 7: Display authorized_keys for verification
ls -l "${SSH_PATH}.ssh/authorized_keys"
cat "${SSH_PATH}.ssh/authorized_keys"
chmod 600 student-admin_key
chmod 644 student-admin_key.pub
# Step 8: Copy the authorized_keys to the remote server
scp -i "${TMP_DIR}/student-admin_key" -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/

# Step 9: Add the key to ssh-agent
eval "$(ssh-agent -s)"
if ssh-add "${TMP_DIR}/student-admin_key"; then
    echo "Key added to ssh-agent successfully."
else
    echo "Error adding key to ssh-agent!"
    exit 1
fi

# Step 10: Verify the authorized_keys on the server
ssh -i "${TMP_DIR}/student-admin_key" -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE} "cat ~/.ssh/authorized_keys"

# Step 11: Check if the project folder exists on the server, create it if it doesn't
ssh -i "${TMP_DIR}/student-admin_key" -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE} "mkdir -p ${REMOTE_PROJECT_PATH}"

# Step 12: Clone the repository locally
git clone ${REPO_URL}

# Step 13: Copy the repository to the project folder on the server
scp -i "${TMP_DIR}/student-admin_key" -P ${PORT} -o StrictHostKeyChecking=no -r ${PROJECT_DIR} student-admin@${MACHINE}:${REMOTE_PROJECT_PATH}/
ssh -i "${TMP_DIR}/student-admin_key" -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE} "ls -al ${REMOTE_PROJECT_PATH}/${PROJECT_DIR} || echo 'Directory not found'"

# Final message
echo "Deployment completed successfully!"
