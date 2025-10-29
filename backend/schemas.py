from pydantic import BaseModel
from models import UserType

class UserBase(BaseModel):
    email: str
    user_type: UserType
    first_name: str
    last_name: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool

    class Config:
        orm_mode = True
