
CREATE TABLE users (
    user_id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    photo_url TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('client', 'trainer')),
    trainer_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(user_id)
);

CREATE TABLE exercises (
    exercise_id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(100),
    muscle_group VARCHAR(100),
    equipment VARCHAR(100),
    difficulty VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE workouts (
    workout_id VARCHAR(255) PRIMARY KEY,
    trainer_id VARCHAR(255) NOT NULL,
    workout_name VARCHAR(255) NOT NULL,
    description TEXT,
    estimated_duration INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(user_id)
);

CREATE TABLE workout_client_ids (
    id INT PRIMARY KEY,
    workout_id VARCHAR(255) NOT NULL,
    client_id VARCHAR(255) NOT NULL,
    FOREIGN KEY (workout_id) REFERENCES workouts(workout_id),
    FOREIGN KEY (client_id) REFERENCES users(user_id)
);

CREATE TABLE workout_exercises (
    id INT PRIMARY KEY,
    workout_id VARCHAR(255) NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    sets INT NOT NULL,
    reps VARCHAR(50),
    rest_seconds INT,
    notes TEXT,
    FOREIGN KEY (workout_id) REFERENCES workouts(workout_id),
    FOREIGN KEY (exercise_name) REFERENCES exercises(name)
);

CREATE TABLE scheduled_workouts (
    scheduled_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    workout_id VARCHAR(255) NOT NULL,
    workout_name VARCHAR(255) NOT NULL,
    scheduled_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (workout_id) REFERENCES workouts(workout_id)
);


CREATE TABLE completed_workouts (
    completed_id INT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    workout_id VARCHAR(255) NOT NULL,
    workout_name VARCHAR(255) NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INT NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (workout_id) REFERENCES workouts(workout_id)
);

CREATE TABLE completed_workout_exercises (
    id INT PRIMARY KEY,
    completed_workout_id INT NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    sets_completed INT,
    reps_completed VARCHAR(50),
    weight DECIMAL(6,2),
    notes TEXT,
    FOREIGN KEY (completed_workout_id) REFERENCES completed_workouts(completed_id),
    FOREIGN KEY (exercise_name) REFERENCES exercises(name)
);

CREATE TABLE personal_records (
    pr_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    weight DECIMAL(6,2) NOT NULL,
    reps INT NOT NULL,
    achieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (exercise_name) REFERENCES exercises(name)
);
