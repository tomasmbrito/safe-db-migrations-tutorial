-- migrate:up
CREATE TABLE users (
  id         bigserial PRIMARY KEY,
  name       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- some existing customers so the table isn't empty
INSERT INTO users (name)
SELECT 'customer ' || g FROM generate_series(1, 200000) AS g;

-- migrate:down
DROP TABLE users;
