from pydantic import BaseModel, ConfigDict # type: ignore
from models import UserType
from datetime import datetime
from typing import Optional

class Token(BaseModel):
    access_token: str
    token_type: str
    user: 'User'

class UserBase(BaseModel):
    email: str
    user_type: UserType
    first_name: str
    last_name: str

class UserCreate(UserBase):
    password: str
    password_confirm: str

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class User(UserBase):
    id: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

class StudentBase(BaseModel):
    user_id: int
    skills: Optional[str] = None
    level: Optional[str] = None

class StudentCreate(StudentBase):
    pass

class StudentUpdate(BaseModel):
    skills: Optional[str] = None
    level: Optional[str] = None

class Student(StudentBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class HighSchoolerBase(BaseModel):
    user_id: int
    current_school: Optional[str] = None
    strong_subjects: Optional[str] = None

class HighSchoolerCreate(HighSchoolerBase):
    pass

class HighSchoolerUpdate(BaseModel):
    current_school: Optional[str] = None
    strong_subjects: Optional[str] = None

class HighSchooler(HighSchoolerBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class CompanyBase(BaseModel):
    user_id: int
    industry: Optional[str] = None
    website: Optional[str] = None

class CompanyCreate(CompanyBase):
    pass

class CompanyUpdate(BaseModel):
    industry: Optional[str] = None
    website: Optional[str] = None

class Company(CompanyBase):
    id: int
    offers: list['Offer'] = []

    model_config = ConfigDict(from_attributes=True)

class UniversityBase(BaseModel):
    user_id: int
    accreditations: Optional[str] = None
    website: Optional[str] = None

class UniversityCreate(UniversityBase):
    pass

class University(UniversityBase):
    id: int
    formations: list['Formation'] = []

class UniversityUpdate(BaseModel):
    accreditations: Optional[str] = None
    website: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class OfferBase(BaseModel):
    title: str
    description: str
    company_id: int

class OfferCreate(OfferBase):
    pass

class Offer(OfferBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class FormationBase(BaseModel):
    title: str
    description: str
    university_id: int

class FormationCreate(FormationBase):
    pass

class Formation(FormationBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

Company.model_rebuild()
University.model_rebuild()

class ConversationBase(BaseModel):
    participant1_id: int
    participant2_id: int

class ConversationCreate(ConversationBase):
    pass

class Conversation(ConversationBase):
    id: int
    messages: list['Message'] = []

    model_config = ConfigDict(from_attributes=True)

class MessageBase(BaseModel):
    content: str
    sender_id: int
    conversation_id: int
    timestamp: str

class MessageCreate(MessageBase):
    pass

class Message(MessageBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

Conversation.model_rebuild()

# Schéma pour la réponse de la liste des conversations
class ConversationDetail(BaseModel):
    id: int
    other_participant: User
    last_message: Optional[Message] = None

    model_config = ConfigDict(from_attributes=True)




# Schéma pour la création d'un match (ce que l'API reçoit)
class MatchCreate(BaseModel):
    user_id: int
    offer_id: Optional[int] = None
    formation_id: Optional[int] = None

# Schéma pour lire un match (ce que l'API renvoie)
class Match(BaseModel):
    id: int
    user_id: int
    offer_id: Optional[int] = None
    formation_id: Optional[int] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class MatchResponse(BaseModel):
    match: Match
    is_new_conversation: bool
    conversation_id: Optional[int] = None

class DeviceTokenUpdate(BaseModel):
    device_token: str
