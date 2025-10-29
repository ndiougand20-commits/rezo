from pydantic import BaseModel
from models import UserType
from typing import Optional

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

class StudentBase(BaseModel):
    user_id: int

class StudentCreate(StudentBase):
    pass

class Student(StudentBase):
    id: int

    class Config:
        orm_mode = True

class HighSchoolerBase(BaseModel):
    user_id: int

class HighSchoolerCreate(HighSchoolerBase):
    pass

class HighSchooler(HighSchoolerBase):
    id: int

    class Config:
        orm_mode = True

class CompanyBase(BaseModel):
    user_id: int

class CompanyCreate(CompanyBase):
    pass

class Company(CompanyBase):
    id: int
    offers: list['Offer'] = []

    class Config:
        orm_mode = True

class UniversityBase(BaseModel):
    user_id: int

class UniversityCreate(UniversityBase):
    pass

class University(UniversityBase):
    id: int
    formations: list['Formation'] = []

    class Config:
        orm_mode = True

class OfferBase(BaseModel):
    title: str
    description: str
    company_id: int

class OfferCreate(OfferBase):
    pass

class Offer(OfferBase):
    id: int

    class Config:
        orm_mode = True

class FormationBase(BaseModel):
    title: str
    description: str
    university_id: int

class FormationCreate(FormationBase):
    pass

class Formation(FormationBase):
    id: int

    class Config:
        orm_mode = True

Company.update_forward_refs()
University.update_forward_refs()
