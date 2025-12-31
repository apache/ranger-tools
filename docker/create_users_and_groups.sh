#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to create users and groups in ranger containers
# This script is designed to be run during container initialization

set -e

# General-purpose function to create a group if it doesn't exist.
create_group_if_not_exists() {
    local groupname=$1

    if ! getent group "$groupname" &>/dev/null; then
        echo "Creating group: $groupname"
        groupadd "$groupname"
        echo "Group $groupname created successfully"
    else
        echo "Group $groupname already exists"
    fi
}

# General-purpose function to create a user if it doesn't exist.
create_user_if_not_exists() {
    local username=$1
    local home_dir=$2
    local primary_group=$3

    if ! id "$username" &>/dev/null; then
        echo "Creating user: $username"
        useradd -g "$primary_group" -m -d "$home_dir" -s /bin/bash "$username"

        # Set a default password
        echo "$username:$username" | chpasswd

        echo "User $username created successfully"
    else
        echo "User $username already exists"
    fi
}

# Function to create users and groups if not exist
create_users_and_groups() {
    local group_name=$1
    local users=$2

    echo "Creating group '$group_name' with users: $users"

    # Create group and users
    create_group_if_not_exists "$group_name"
    for u in $users; do
        create_user_if_not_exists "$u" "/home/$u" "$group_name"
    done
}

# Main function to create all users and groups if not exist
create_all_users_and_groups() {
    echo "Starting user and group creation..."

    # Create ranger group and users
    create_users_and_groups "ranger" "ranger rangeradmin rangerusersync rangertagsync rangerkms rangerauditserver"

    # Create hadoop group and users
    create_users_and_groups "hadoop" "hdfs yarn hive hbase kafka ozone"

    # Create knox group and user
    create_users_and_groups "knox" "knox"

    # Create test users in test group
    create_users_and_groups "testgroup" "testuser1 testuser2 testuser3"

    echo "User and group creation completed successfully..."
}

# Execute the main function
create_all_users_and_groups