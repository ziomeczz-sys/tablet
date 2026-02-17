CREATE TABLE IF NOT EXISTS tablet_families (
    citizenid VARCHAR(50) PRIMARY KEY,
    family_name VARCHAR(128) NOT NULL,
    created_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS tablet_faction_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    who VARCHAR(128) NOT NULL,
    src INT NOT NULL,
    rank_name VARCHAR(128) NOT NULL,
    action_name VARCHAR(64) NOT NULL,
    comment TEXT,
    amount INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL
);
