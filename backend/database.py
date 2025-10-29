from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# When running the backend inside a Docker container, the host should be 'db'
# For now, we use 'localhost' as we run the script directly on the host
SQLALCHEMY_DATABASE_URL = "postgresql://rezobd_user:rezobd_password@localhost:5432/rezo"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
