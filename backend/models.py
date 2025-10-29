from sqlalchemy import Boolean, Column, Integer, String, Enum
from database import Base
import enum

class UserType(str, enum.Enum):
    STUDENT = "student"
    HIGH_SCHOOL = "high_school"
    COMPANY = "company"
    UNIVERSITY = "university"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    user_type = Column(Enum(UserType))
    first_name = Column(String)
    last_name = Column(String)
