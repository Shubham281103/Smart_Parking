
# Smart Parking System - Backend

This project is the complete backend for a smart parking system, including a REST API, PostgreSQL database, and Nginx reverse proxy, all containerized with Docker.

## Features

- **User Authentication:** Secure user registration and login using JWT.
- **Hierarchical Parking Structure:** Full CRUD API for managing Parking Lots, Floors, Rows, and Slots.
- **Real-time Slot Updates:** Dedicated endpoint for IoT devices (e.g., Raspberry Pi) to push slot status changes.
- **API Documentation:** Interactive Swagger UI for exploring and testing the API.
- **Containerized:** Fully containerized with Docker and Docker Compose for easy setup and deployment.
- **Automated Testing:** Includes a suite of `pytest` unit/integration tests and an end-to-end system test script.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## How to Run the Application

Follow these steps to get the application running on your local machine.

### 1. Set Up Environment Variables

The application uses a `.env` file to manage environment variables. An example file (`.env.example`) is provided.

First, make a copy of the example file:

```sh
# For Windows (Command Prompt)
copy .env.example .env

# For Windows (PowerShell)
cp .env.example .env

# For Linux/macOS
cp .env.example .env
```

The default values in the `.env` file are pre-configured to work with the `docker-compose.yml` setup, so you don't need to change anything unless you want to customize the database credentials or secret keys.

### 2. Build and Start the Containers

This command will build the Docker images for the Flask application and Nginx, and start all the services (app, database, proxy) in the background.

```sh
docker-compose up --build -d
```

### 3. Initialize the Database

The first time you start the application, you need to create the database tables from the SQLAlchemy models. The following commands use Flask-Migrate to do this.

Run these commands one by one:

```sh
# 1. Initialize the migration environment (only needs to be run once ever)
docker-compose exec app flask db init

# 2. Create the initial migration script
docker-compose exec app flask db migrate -m "Initial migration"

# 3. Apply the migration to the database
docker-compose exec app flask db upgrade
```

Your application is now running!

## Accessing the Application

Once the services are running, you can access the application in your web browser.

- **Main Landing Page:**
  - **URL:** `http://localhost`
  - **Description:** Visit this URL to see a welcome page confirming that the application is running correctly.

- **API Documentation (Swagger UI):**
  - **URL:** `http://localhost/apidocs`
  - **Description:** This is an interactive page where you can see all available API endpoints, their required parameters, and test them directly from your browser. This is the primary tool for API testing.

## Running the Tests

The project includes two types of tests.

### Pytest (Unit/Integration Tests)

These tests check the application's internal logic using an in-memory database. They are fast and ideal for running during development.

```sh
docker-compose exec app pytest
```

### End-to-End Test

This script tests the entire live system running in Docker, including the Nginx proxy and PostgreSQL database. It's a great way to verify that all the pieces are working together correctly.

```sh
python e2e_test.py
```

## Stopping the Application

To stop all the running containers, use:

```sh
docker-compose down
``` 
=======
# vibe_coding-parking_app_cloud_server
